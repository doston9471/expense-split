# frozen_string_literal: true

require "rails_helper"

RSpec.describe Memberships::Services::JoinRoomService, type: :model do
  let(:service) { described_class.new }
  let(:room) { create(:room) }
  let(:joiner) { create(:user) }

  it "adds member and publishes MemberJoined" do
    command = Memberships::Commands::JoinRoom.new(invite_token: room.invite_token, user_id: joiner.id)
    expect { service.call(command) }.to change { room.memberships.where(user: joiner).count }.from(0).to(1)

    events = Rails.configuration.x.domain_event_store.read.stream("Room$#{room.id}").to_a
    expect(events.last).to be_a(Memberships::Events::MemberJoined)
  end

  it "rejects archived room" do
    room.update!(status: "archived", archived_at: Time.current)
    expect do
      service.call(Memberships::Commands::JoinRoom.new(invite_token: room.invite_token, user_id: joiner.id))
    end.to raise_error(ArgumentError, "room is archived")
  end

  it "rejects duplicate membership" do
    create(:membership, room:, user: joiner, role: "member")
    expect do
      service.call(Memberships::Commands::JoinRoom.new(invite_token: room.invite_token, user_id: joiner.id))
    end.to raise_error(ArgumentError, "already a member")
  end
end
