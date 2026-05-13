# frozen_string_literal: true

require "rails_helper"

RSpec.describe Room, type: :model do
  subject { build(:room) }

  it { is_expected.to belong_to(:owner).class_name("User") }
  it { is_expected.to have_many(:memberships).dependent(:destroy) }
  it { is_expected.to have_many(:members).through(:memberships).source(:user) }
  it { is_expected.to have_many(:expenses).dependent(:destroy) }
  it { is_expected.to have_many(:balances).dependent(:destroy) }
  it { is_expected.to have_many(:settlements).dependent(:destroy) }
  it { is_expected.to have_many(:invitations).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:invite_token) }
  it { is_expected.to validate_uniqueness_of(:invite_token) }
  it { is_expected.to validate_inclusion_of(:status).in_array(Room::STATUSES) }

  describe "#archived?" do
    it "is true when status is archived" do
      expect(build(:room, status: "archived")).to be_archived
    end

    it "is false when active" do
      expect(build(:room, status: "active")).not_to be_archived
    end
  end
end
