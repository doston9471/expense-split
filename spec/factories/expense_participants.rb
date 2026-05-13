# frozen_string_literal: true

FactoryBot.define do
  factory :expense_participant do
    expense
    user { expense.paid_by }
  end
end
