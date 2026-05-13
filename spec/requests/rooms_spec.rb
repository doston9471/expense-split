# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rooms", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  it "creates a room via domain service" do
    expect do
      post rooms_path, params: { room: { name: "Paris Trip" } }
    end.to change(Room, :count).by(1)

    expect(response).to redirect_to(room_path(Room.last))
    expect(Membership.where(room: Room.last, user:, role: "owner")).to exist
  end

  it "lists rooms for the signed-in user" do
    room = create(:room, owner: user)

    get rooms_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(room.name)
  end
end
