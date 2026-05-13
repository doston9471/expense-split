# frozen_string_literal: true

module Expenses
  module Services
    class DeleteExpenseService
      def initialize(
        expenses: Repositories::ExpenseRepository.new,
        event_store: Rails.configuration.x.domain_event_store
      )
        @expenses = expenses
        @event_store = event_store
      end

      def call(command)
        expense = @expenses.find(command.expense_id)
        raise ArgumentError, "forbidden" unless expense.created_by_id == command.actor_id

        room_id = expense.room_id
        expense_id = expense.id

        ::ApplicationRecord.transaction do
          @expenses.destroy!(expense)
          @event_store.publish(
            Events::ExpenseDeleted.new(
              data: {
                room_id:,
                expense_id:
              }
            ),
            stream_name: stream(room_id)
          )
        end
      end

      private

      def stream(room_id)
        "Room$#{room_id}"
      end
    end
  end
end
