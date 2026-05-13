# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invitations::Policies::InvitationEligibilityPolicy, type: :model do
  subject(:policy) { described_class.new }

  describe "#validate_room_active!" do
    it "raises when room is archived" do
      room = build(:room, status: "archived")
      expect { policy.validate_room_active!(room) }.to raise_error(ArgumentError, "room is archived")
    end

    it "does not raise for active room" do
      room = build(:room, status: "active")
      expect { policy.validate_room_active!(room) }.not_to raise_error
    end
  end

  describe "#validate_inviter_member!" do
    it "raises when user is not a member" do
      room = create(:room)
      stranger = create(:user)
      expect do
        policy.validate_inviter_member!(room_id: room.id, user_id: stranger.id)
      end.to raise_error(ArgumentError, "only room members can invite")
    end

    it "does not raise for a member" do
      room = create(:room)
      expect do
        policy.validate_inviter_member!(room_id: room.id, user_id: room.owner_id)
      end.not_to raise_error
    end
  end

  describe "#validate_email!" do
    it "allows blank" do
      expect { policy.validate_email!(nil) }.not_to raise_error
      expect { policy.validate_email!("") }.not_to raise_error
    end

    it "raises on malformed email" do
      expect { policy.validate_email!("bad") }.to raise_error(ArgumentError, "invalid email")
    end

    it "allows valid email" do
      expect { policy.validate_email!("ok@example.com") }.not_to raise_error
    end
  end
end
