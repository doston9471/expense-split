# frozen_string_literal: true

require "rails_helper"

RSpec.describe Expenses::Policies::ExpenseIntegrityPolicy, type: :model do
  subject(:policy) { described_class.new(memberships:) }

  let(:memberships) { instance_double(Memberships::Repositories::MembershipRepository, room_member_ids: [ "u1", "u2" ].to_set) }

  describe "#validate!" do
    it "passes when payer and participants are members" do
      expect do
        policy.validate!(room_id: "r", paid_by_id: "u1", participant_ids: %w[u1 u2])
      end.not_to raise_error
    end

    it "raises when payer is not a member" do
      expect do
        policy.validate!(room_id: "r", paid_by_id: "u9", participant_ids: %w[u1])
      end.to raise_error(ArgumentError, "payer must be a room member")
    end

    it "raises when participants empty" do
      expect do
        policy.validate!(room_id: "r", paid_by_id: "u1", participant_ids: [])
      end.to raise_error(ArgumentError, "at least one participant required")
    end

    it "raises when a participant is not a member" do
      expect do
        policy.validate!(room_id: "r", paid_by_id: "u1", participant_ids: %w[u1 u9])
      end.to raise_error(ArgumentError, "participants must be room members")
    end
  end

  describe "#validate_split!" do
    it "allows equal" do
      expect { policy.validate_split!("equal") }.not_to raise_error
    end

    it "rejects other split types for now" do
      expect { policy.validate_split!("percentage") }.to raise_error(ArgumentError, "only equal split is implemented")
    end
  end
end
