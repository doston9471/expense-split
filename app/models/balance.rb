# frozen_string_literal: true

# Read-model projection: `amount_cents` is how much `debtor` owes `creditor` in `currency`.
class Balance < ApplicationRecord
  belongs_to :room
  belongs_to :creditor, class_name: "User"
  belongs_to :debtor, class_name: "User"

  validates :amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency, presence: true
end
