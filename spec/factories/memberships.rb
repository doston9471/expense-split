# frozen_string_literal: true

FactoryBot.define do
  factory :membership do
    user
    room
    role { "member" }
  end
end
