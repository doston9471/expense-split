# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rooms::Repositories::RoomRepository, type: :model do
  subject(:repo) { described_class.new }

  let(:owner) { create(:user) }

  it "#find returns persisted room" do
    room = create(:room)
    expect(repo.find(room.id)).to eq(room)
  end

  it "#find_by_invite_token! finds by token" do
    room = create(:room)
    expect(repo.find_by_invite_token!(room.invite_token)).to eq(room)
  end

  it "#create! persists room" do
    room = repo.create!(owner_id: owner.id, name: "Repo Room", invite_token: SecureRandom.urlsafe_base64(12))
    expect(room).to be_persisted
  end

  it "#find_by_invite_token! raises when missing" do
    expect { repo.find_by_invite_token!("missing-token-xyz") }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "#archive! sets archived state" do
    room = create(:room)
    repo.archive!(room)
    expect(room.reload).to be_archived
  end
end
