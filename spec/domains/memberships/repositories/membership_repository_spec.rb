# frozen_string_literal: true

require "rails_helper"

RSpec.describe Memberships::Repositories::MembershipRepository, type: :model do
  subject(:repo) { described_class.new }

  let(:room) { create(:room) }
  let(:user) { create(:user) }

  it "#member? reflects membership" do
    expect(repo.member?(room_id: room.id, user_id: room.owner_id)).to be true
    expect(repo.member?(room_id: room.id, user_id: user.id)).to be false
  end

  it "#room_member_ids lists members" do
    create(:membership, room:, user:, role: "member")
    ids = repo.room_member_ids(room.id)
    expect(ids).to contain_exactly(room.owner_id, user.id)
  end

  it "#create_member! and #destroy! round-trip" do
    repo.create_member!(room_id: room.id, user_id: user.id)
    m = repo.find_membership(room_id: room.id, user_id: user.id)
    expect(m).to be_present
    repo.destroy!(m)
    expect(repo.find_membership(room_id: room.id, user_id: user.id)).to be_nil
  end
end
