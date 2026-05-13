# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "password12345" }
    password_confirmation { "password12345" }
    display_name { Faker::Name.name }
  end
end
