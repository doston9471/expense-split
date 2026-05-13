# frozen_string_literal: true

module Expenses
  module Services
    class CreateExpenseService
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
        @integrity.validate_split!(command.split_type)
        @integrity.validate!(
          room_id: command.room_id,
          paid_by_id: command.paid_by_id,
          participant_ids: command.participant_ids
        )

        ::ApplicationRecord.transaction do
          expense = @expenses.create_with_participants!(
            {
              room_id: command.room_id,
              title: command.title,
              amount_cents: command.amount_cents,
              currency: command.currency,
              paid_by_id: command.paid_by_id,
              created_by_id: command.actor_id,
              split_type: command.split_type
            },
            command.participant_ids.uniq
          )

          @event_store.publish(
            Events::ExpenseCreated.new(
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
