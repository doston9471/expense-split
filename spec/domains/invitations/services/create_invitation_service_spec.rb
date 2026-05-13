# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invitations::Services::CreateInvitationService, type: :model do
  let(:service) { described_class.new }
  let(:room) { create(:room) }

  it "creates pending invitation with token and publishes InvitationCreated" do
    command = Invitations::Commands::CreateInvitation.new(
      room_id: room.id,
      invited_by_id: room.owner_id,
      email: "guest@example.com"
    )
    invitation = service.call(command)
    expect(invitation).to be_persisted
    expect(invitation.email).to eq("guest@example.com")
    expect(invitation.status).to eq("pending")
    expect(invitation.token).to be_present

    events = Rails.configuration.x.domain_event_store.read.stream("Room$#{room.id}").to_a
    expect(events.last).to be_a(Invitations::Events::InvitationCreated)
  end

  it "allows blank email for open invite" do
    command = Invitations::Commands::CreateInvitation.new(
      room_id: room.id,
      invited_by_id: room.owner_id,
      email: nil
    )
    invitation = service.call(command)
    expect(invitation.email).to be_nil
  end

  it "rejects archived room" do
    room.update!(status: "archived", archived_at: Time.current)
    command = Invitations::Commands::CreateInvitation.new(
      room_id: room.id,
      invited_by_id: room.owner_id,
      email: nil
    )
    expect { service.call(command) }.to raise_error(ArgumentError, "room is archived")
  end
end
