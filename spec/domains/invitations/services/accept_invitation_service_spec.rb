# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invitations::Services::AcceptInvitationService, type: :model do
  let(:service) { described_class.new }
  let(:room) { create(:room) }
  let(:invitee) { create(:user, email: "invitee@example.com") }
  let(:token) { SecureRandom.urlsafe_base64(16) }

  let!(:invitation) do
    create(
      :invitation,
      room:,
      invited_by: room.owner,
      email: "invitee@example.com",
      token:,
      status: "pending",
      expires_at: 2.days.from_now
    )
  end

  it "adds membership and publishes MemberJoined and InvitationAccepted" do
    command = Invitations::Commands::AcceptInvitation.new(token: invitation.token, user_id: invitee.id)
    expect { service.call(command) }.to change { room.memberships.exists?(user_id: invitee.id) }.from(false).to(true)

    invitation.reload
    expect(invitation.status).to eq("accepted")
    expect(invitation.accepted_by_id).to eq(invitee.id)

    events = Rails.configuration.x.domain_event_store.read.stream("Room$#{room.id}").to_a
    types = events.map(&:class)
    expect(types).to include(Memberships::Events::MemberJoined, Invitations::Events::InvitationAccepted)
  end

  it "rejects email mismatch" do
    wrong = create(:user, email: "other@example.com")
    command = Invitations::Commands::AcceptInvitation.new(token: invitation.token, user_id: wrong.id)
    expect { service.call(command) }.to raise_error(ArgumentError, "sign in with the invited email address to accept")
  end

  context "open invitation (no email)" do
    let!(:open_invitation) do
      create(
        :invitation,
        room:,
        invited_by: room.owner,
        email: nil,
        token: SecureRandom.urlsafe_base64(16),
        status: "pending",
        expires_at: 2.days.from_now
      )
    end

    it "accepts for any user" do
      other = create(:user)
      command = Invitations::Commands::AcceptInvitation.new(token: open_invitation.token, user_id: other.id)
      expect { service.call(command) }.to change { room.memberships.exists?(user_id: other.id) }.to(true)
    end
  end

  it "marks accepted when user was already a member" do
    create(:membership, room:, user: invitee, role: "member")
    command = Invitations::Commands::AcceptInvitation.new(token: invitation.token, user_id: invitee.id)
    service.call(command)
    expect(invitation.reload.status).to eq("accepted")
  end
end
