# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invitations::Repositories::InvitationRepository, type: :model do
  subject(:repo) { described_class.new }

  let(:room) { create(:room) }

  it "#find_by_token! finds invitation" do
    inv = create(:invitation, room:, token: "unique-repo-token")
    expect(repo.find_by_token!("unique-repo-token")).to eq(inv)
  end

  it "#accept! and #revoke! update status" do
    inv = create(:invitation, room:, status: "pending")
    user = create(:user)
    repo.accept!(inv, user:)
    expect(inv.reload.status).to eq("accepted")

    inv2 = create(:invitation, room:, status: "pending")
    repo.revoke!(inv2)
    expect(inv2.reload.status).to eq("revoked")
  end
end
