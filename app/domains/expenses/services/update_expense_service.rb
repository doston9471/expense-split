# frozen_string_literal: true

module Expenses
  module Services
    class UpdateExpenseService
      def initialize(
        expenses: Repositories::ExpenseRepository.new,
        integrity: Policies::ExpenseIntegrityPolicy.new,
        event_store: Rails.configuration.x.domain_event_store
      )
        @expenses = expenses
        @integrity = integrity
        @event_store = event_store
      end

      def call(command)
        expense = @expenses.find(command.expense_id)
        raise ArgumentError, "forbidden" unless expense.created_by_id == command.actor_id

        @integrity.validate_split!(command.split_type)
        @integrity.validate!(
          room_id: expense.room_id,
          paid_by_id: command.paid_by_id,
          participant_ids: command.participant_ids
        )

        ::ApplicationRecord.transaction do
          @expenses.update!(
            expense,
            title: command.title,
            amount_cents: command.amount_cents,
            currency: command.currency,
            paid_by_id: command.paid_by_id,
            split_type: command.split_type
          )
          @expenses.replace_participants!(expense, command.participant_ids.uniq)
          expense.reload

          @event_store.publish(
            Events::ExpenseUpdated.new(
              data: {
                room_id: expense.room_id,
                expense_id: expense.id,
                amount_cents: expense.amount_cents,
                currency: expense.currency,
                paid_by_id: expense.paid_by_id,
                participant_ids: expense.expense_participants.pluck(:user_id),
                split_type: expense.split_type
              }
            ),
            stream_name: stream(expense.room_id)
          )
          expense
        end
      end

      private

      def stream(room_id)
        "Room$#{room_id}"
      end
    end
  end
end
