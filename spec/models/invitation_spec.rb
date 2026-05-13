# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invitation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:room) }
    it { is_expected.to belong_to(:invited_by).optional }
    it { is_expected.to belong_to(:accepted_by).optional }
  end

  describe "validations" do
    subject { build(:invitation) }

    it { is_expected.to validate_presence_of(:token) }
    it { is_expected.to validate_uniqueness_of(:token) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Invitation::STATUSES) }
    it { is_expected.to allow_value(nil).for(:email) }
    it { is_expected.to allow_value("").for(:email) }
    it { is_expected.to allow_value("friend@example.com").for(:email) }
    it { is_expected.not_to allow_value("not-an-email").for(:email) }
  end

  describe "#expired?" do
    it "is false when expires_at is blank" do
      expect(build(:invitation, expires_at: nil)).not_to be_expired
    end

    it "is true when expires_at is in the past" do
      expect(build(:invitation, expires_at: 1.day.ago)).to be_expired
    end
  end

  describe "#usable?" do
    it "is true for pending, unexpired invitation" do
      inv = build(:invitation, status: "pending", expires_at: 1.day.from_now)
      expect(inv).to be_usable
    end

    it "is false when revoked" do
      inv = build(:invitation, status: "revoked", expires_at: 1.day.from_now)
      expect(inv).not_to be_usable
    end

    it "is false when expired" do
      inv = build(:invitation, status: "pending", expires_at: 1.hour.ago)
      expect(inv).not_to be_usable
    end
  end

  describe ".open" do
    it "returns pending invitations that are not expired" do
      room = create(:room)
      open_inv = create(:invitation, room:, status: "pending", expires_at: 2.days.from_now)
      create(:invitation, room:, status: "pending", expires_at: 1.hour.ago)
      create(:invitation, room:, status: "accepted", expires_at: 2.days.from_now)

      expect(described_class.open).to contain_exactly(open_inv)
    end
  end
end
