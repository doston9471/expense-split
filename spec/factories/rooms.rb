# frozen_string_literal: true

FactoryBot.define do
  factory :room do
    association :owner, factory: :user
    sequence(:name) { |n| "Trip #{n}" }
    invite_token { SecureRandom.urlsafe_base64(18) }
    status { "active" }

    after(:create) do |room|
      Membership.find_or_create_by!(room:, user: room.owner) do |m|
        m.role = "owner"
      end
    end
  end
end
