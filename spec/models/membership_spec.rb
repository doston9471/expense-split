# frozen_string_literal: true

require "rails_helper"

RSpec.describe Membership, type: :model do
  subject { build(:membership) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:room) }
  it { is_expected.to validate_inclusion_of(:role).in_array(Membership::ROLES) }
  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:room_id).ignoring_case_sensitivity }
end
