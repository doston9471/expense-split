# frozen_string_literal: true

FactoryBot.define do
  factory :expense do
    room
    paid_by { room.owner }
    created_by { room.owner }
    title { "Dinner" }
    amount_cents { 10_000 }
    currency { "USD" }
    split_type { "equal" }

    transient do
      participant_list { nil }
    end

    after(:create) do |expense, evaluator|
      users = evaluator.participant_list || [ expense.paid_by ]
      users.each do |u|
        ExpenseParticipant.create!(expense:, user: u)
      end
    end
  end
end
