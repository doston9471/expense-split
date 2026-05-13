# frozen_string_literal: true

require "rails_helper"

RSpec.describe Balance, type: :model do
  it { is_expected.to belong_to(:room) }
  it { is_expected.to belong_to(:creditor).class_name("User") }
  it { is_expected.to belong_to(:debtor).class_name("User") }
  it { is_expected.to validate_numericality_of(:amount_cents).only_integer.is_greater_than_or_equal_to(0) }
  it { is_expected.to validate_presence_of(:currency) }

  it "enforces one balance row per room/creditor/debtor triple" do
    room = create(:room)
    creditor = create(:user)
    debtor = create(:user)
    create(:balance, room:, creditor:, debtor:, amount_cents: 50, currency: "USD")
    dup = build(:balance, room:, creditor:, debtor:, amount_cents: 10, currency: "USD")
    expect { dup.save! }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
