# frozen_string_literal: true

module Expenses
  module Commands
    DeleteExpense = Data.define(:expense_id, :actor_id)
  end
end
