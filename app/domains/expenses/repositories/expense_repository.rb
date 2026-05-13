# frozen_string_literal: true

module Expenses
  module Repositories
    class ExpenseRepository
      def find(expense_id)
        ::Expense.find(expense_id)
      end

      def create_with_participants!(attrs, participant_ids)
        ::Expense.transaction do
          expense = ::Expense.create!(attrs)
          participant_ids.each do |user_id|
            ::ExpenseParticipant.create!(expense:, user_id:)
          end
          expense.reload
        end
      end

      def replace_participants!(expense, participant_ids)
        ::Expense.transaction do
          expense.expense_participants.delete_all
          participant_ids.each do |user_id|
            ::ExpenseParticipant.create!(expense:, user_id:)
          end
          expense.reload
        end
      end

      def update!(expense, attrs)
        expense.update!(attrs)
      end

      def destroy!(expense)
        expense.destroy!
      end
    end
  end
end
