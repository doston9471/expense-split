# frozen_string_literal: true

require "rails_helper"

RSpec.describe Settlements::Repositories::SettlementRepository, type: :model do
  subject(:repo) { described_class.new }

  let(:room) { create(:room) }
  let(:bob) { create(:user) }

  before { create(:membership, room:, user: bob, role: "member") }

  it "#create! persists settlement" do
    s = repo.create!(
      room_id: room.id,
      payer_id: bob.id,
      payee_id: room.owner_id,
      amount_cents: 100,
      currency: "USD",
      note: nil
    )
    expect(s).to be_persisted
  end
end
