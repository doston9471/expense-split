# frozen_string_literal: true

# `payer` pays `payee`; reduces debt that `payer` owes to `payee` in balance projection.
class Settlement < ApplicationRecord
  belongs_to :room
  belongs_to :payer, class_name: "User"
  belongs_to :payee, class_name: "User"

  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, presence: true
end
