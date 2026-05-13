# frozen_string_literal: true

FactoryBot.define do
  factory :balance do
    room
    association :creditor, factory: :user
    association :debtor, factory: :user
    amount_cents { 100 }
    currency { "USD" }
  end
end
