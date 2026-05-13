# frozen_string_literal: true

FactoryBot.define do
  factory :settlement do
    room
    payer { room.owner }
    association :payee, factory: :user
    amount_cents { 1000 }
    currency { "USD" }
    note { nil }
  end
end
