# frozen_string_literal: true

class Membership < ApplicationRecord
  ROLES = %w[owner member].freeze

  belongs_to :user
  belongs_to :room

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :room_id }
end
