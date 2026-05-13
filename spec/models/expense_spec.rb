# frozen_string_literal: true

require "rails_helper"

RSpec.describe Expense, type: :model do
  subject { build(:expense) }

  it { is_expected.to belong_to(:room) }
  it { is_expected.to belong_to(:paid_by).class_name("User") }
  it { is_expected.to belong_to(:created_by).class_name("User") }
  it { is_expected.to have_many(:expense_participants).dependent(:destroy) }
  it { is_expected.to have_many(:participants).through(:expense_participants).source(:user) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_numericality_of(:amount_cents).only_integer.is_greater_than(0) }
  it { is_expected.to validate_presence_of(:currency) }
  it { is_expected.to validate_inclusion_of(:split_type).in_array(Expense::SPLIT_TYPES) }

  describe "#participant_ids" do
    it "returns user ids of participants" do
      room = create(:room)
      expense = create(:expense, room:, participant_list: [ room.owner ])
      expect(expense.participant_ids).to eq([ room.owner.id ])
    end
  end
end
