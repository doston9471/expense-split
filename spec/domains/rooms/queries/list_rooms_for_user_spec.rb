# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rooms::Queries::ListRoomsForUser, type: :model do
  subject(:query) { described_class.new }

  let(:user) { create(:user) }
  let!(:active_room) { create(:room, name: "Alpha") }
  let!(:archived_room) { create(:room, name: "Beta", status: "archived", archived_at: Time.current) }

  before do
    create(:membership, room: active_room, user:, role: "member")
    create(:membership, room: archived_room, user:, role: "member")
  end

  it "returns only active memberships for active rooms" do
    result = query.call(user_id: user.id)
    expect(result).to contain_exactly(active_room)
  end
end
