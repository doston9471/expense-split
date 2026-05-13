# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invitations::Services::RevokeInvitationService, type: :model do
  let(:service) { described_class.new }
  let(:room) { create(:room) }
  let!(:invitation) { create(:invitation, room:, invited_by: room.owner, status: "pending") }

  it "revokes pending invitation for owner" do
    command = Invitations::Commands::RevokeInvitation.new(invitation_id: invitation.id, actor_id: room.owner_id)
    service.call(command)
    expect(invitation.reload.status).to eq("revoked")

    events = Rails.configuration.x.domain_event_store.read.stream("Room$#{room.id}").to_a
    expect(events.last).to be_a(Invitations::Events::InvitationRevoked)
  end

  it "allows inviter to revoke" do
    member = create(:user)
    create(:membership, room:, user: member, role: "member")
    inv = create(:invitation, room:, invited_by: member, status: "pending")
    command = Invitations::Commands::RevokeInvitation.new(invitation_id: inv.id, actor_id: member.id)
    service.call(command)
    expect(inv.reload.status).to eq("revoked")
  end

  it "rejects stranger" do
    stranger = create(:user)
    command = Invitations::Commands::RevokeInvitation.new(invitation_id: invitation.id, actor_id: stranger.id)
    expect { service.call(command) }.to raise_error(ArgumentError, "forbidden")
  end

  it "rejects revoking accepted invitation" do
    invitation.update!(status: "accepted", accepted_at: Time.current, accepted_by: room.owner)
    command = Invitations::Commands::RevokeInvitation.new(invitation_id: invitation.id, actor_id: room.owner_id)
    expect { service.call(command) }.to raise_error(ArgumentError, "invitation cannot be revoked")
  end
end
