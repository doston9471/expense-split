# frozen_string_literal: true

require "rails_helper"

RSpec.describe Memberships::Services::LeaveRoomService, type: :model do
  let(:service) { described_class.new }
  let(:room) { create(:room) }
  let(:member) { create(:user) }

  before { create(:membership, room:, user: member, role: "member") }

  it "removes member and publishes MemberLeft" do
    command = Memberships::Commands::LeaveRoom.new(room_id: room.id, user_id: member.id)
    expect { service.call(command) }.to change { room.memberships.exists?(user_id: member.id) }.from(true).to(false)

    events = Rails.configuration.x.domain_event_store.read.stream("Room$#{room.id}").to_a
    expect(events.last).to be_a(Memberships::Events::MemberLeft)
  end

  it "rejects owner leaving" do
    expect do
      service.call(Memberships::Commands::LeaveRoom.new(room_id: room.id, user_id: room.owner_id))
    end.to raise_error(ArgumentError, "owner cannot leave; archive the room or transfer ownership")
  end

  it "rejects non-member" do
    stranger = create(:user)
    expect do
      service.call(Memberships::Commands::LeaveRoom.new(room_id: room.id, user_id: stranger.id))
    end.to raise_error(ArgumentError, "not a member")
  end
end
