# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExpenseParticipant, type: :model do
  subject { build(:expense_participant) }

  it { is_expected.to belong_to(:expense) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:expense_id).ignoring_case_sensitivity }
end
