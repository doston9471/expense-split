# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  it { is_expected.to have_many(:memberships).dependent(:destroy) }
  it { is_expected.to have_many(:rooms).through(:memberships) }
  it { is_expected.to have_many(:owned_rooms).class_name("Room").with_foreign_key(:owner_id).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:display_name) }
  it { is_expected.to validate_length_of(:display_name).is_at_most(120) }
end
