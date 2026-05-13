# frozen_string_literal: true

require "rails_helper"
require "action_cable/test_helper"

RSpec.describe Rooms::Subscribers::BroadcastRoomRefresh, type: :model do
  include ActionCable::TestHelper
  include ActiveSupport::Testing::Assertions

  subject(:subscriber) { described_class.new }

  it "broadcasts a Turbo refresh on the room live stream" do
    room = create(:room)
    stream = Turbo::StreamsChannel.send(:stream_name_from, [ room, :live ])

    assert_broadcasts(stream, 1) do
      subscriber.call(Expenses::Events::ExpenseCreated.new(data: { room_id: room.id }))
    end
  end

  it "no-ops when room_id is missing" do
    expect do
      subscriber.call(Expenses::Events::ExpenseCreated.new(data: {}))
    end.not_to raise_error
  end
end
