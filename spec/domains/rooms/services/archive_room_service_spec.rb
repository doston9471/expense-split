# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rooms::Services::ArchiveRoomService, type: :model do
  let(:service) { described_class.new }
  let(:room) { create(:room) }

  it "archives when actor is owner" do
    service.call(Rooms::Commands::ArchiveRoom.new(room_id: room.id, actor_id: room.owner_id))
    expect(room.reload).to be_archived
    events = Rails.configuration.x.domain_event_store.read.stream("Room$#{room.id}").to_a
    expect(events.last).to be_a(Rooms::Events::RoomArchived)
  end

  it "rejects non-owner" do
    other = create(:user)
    expect do
      service.call(Rooms::Commands::ArchiveRoom.new(room_id: room.id, actor_id: other.id))
    end.to raise_error(ArgumentError, "only the room owner can archive")
  end

  it "rejects double archive" do
    service.call(Rooms::Commands::ArchiveRoom.new(room_id: room.id, actor_id: room.owner_id))
    expect do
      service.call(Rooms::Commands::ArchiveRoom.new(room_id: room.id, actor_id: room.owner_id))
    end.to raise_error(ArgumentError, "room already archived")
  end
end
