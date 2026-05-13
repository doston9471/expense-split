# frozen_string_literal: true

FactoryBot.define do
  factory :invitation do
    room
    invited_by { room.owner }
    email { nil }
    token { SecureRandom.urlsafe_base64(16) }
    status { "pending" }
    expires_at { 14.days.from_now }
  end
end
