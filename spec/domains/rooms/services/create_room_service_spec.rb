# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rooms::Services::CreateRoomService, type: :model do
  let(:owner) { create(:user) }
  let(:service) { described_class.new }

  it "creates room, owner membership, and publishes RoomCreated" do
    command = Rooms::Commands::CreateRoom.new(owner_id: owner.id, name: "Paris Trip")

    expect { service.call(command) }.to change(Room, :count).by(1).and change(Membership, :count).by(1)

    room = Room.find_by!(name: "Paris Trip")
    expect(room.owner_id).to eq(owner.id)
    expect(Membership.find_by!(room:, user: owner).role).to eq("owner")

    events = Rails.configuration.x.domain_event_store.read.stream("Room$#{room.id}").to_a
    expect(events.size).to eq(1)
    expect(events.first).to be_a(Rooms::Events::RoomCreated)
  end
end
