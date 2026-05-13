# frozen_string_literal: true

require "rails_helper"

RSpec.describe Settlement, type: :model do
  subject { build(:settlement) }

  it { is_expected.to belong_to(:room) }
  it { is_expected.to belong_to(:payer).class_name("User") }
  it { is_expected.to belong_to(:payee).class_name("User") }
  it { is_expected.to validate_numericality_of(:amount_cents).only_integer.is_greater_than(0) }
  it { is_expected.to validate_presence_of(:currency) }
end
