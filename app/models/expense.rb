# frozen_string_literal: true

class Expense < ApplicationRecord
  SPLIT_TYPES = %w[equal exact percentage shares].freeze

  belongs_to :room
  belongs_to :paid_by, class_name: "User"
  belongs_to :created_by, class_name: "User"
  has_many :expense_participants, dependent: :destroy
  has_many :participants, through: :expense_participants, source: :user

  def participant_ids
    expense_participants.pluck(:user_id)
  end

  validates :title, presence: true
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, presence: true
  validates :split_type, inclusion: { in: SPLIT_TYPES }
end
