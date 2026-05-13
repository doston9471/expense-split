# frozen_string_literal: true

# Persistence model for the Rooms bounded context. Business rules live under
# `app/domains/rooms` (commands, services, policies); this class stays thin.
class Room < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :memberships, dependent: :destroy
  has_many :members, through: :memberships, source: :user
  has_many :expenses, dependent: :destroy
  has_many :balances, dependent: :destroy
  has_many :settlements, dependent: :destroy
  has_many :invitations, dependent: :destroy

  STATUSES = %w[active archived].freeze

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :invite_token, presence: true, uniqueness: true

  scope :active, -> { where(status: "active") }

  def archived?
    status == "archived"
  end
end
