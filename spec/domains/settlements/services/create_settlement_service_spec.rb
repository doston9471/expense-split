# frozen_string_literal: true

require "rails_helper"

RSpec.describe Settlements::Services::CreateSettlementService, type: :model do
  let(:service) { described_class.new }
  let(:room) { create(:room) }
  let(:bob) { create(:user) }

  before { create(:membership, room:, user: bob, role: "member") }

  let(:command) do
    Settlements::Commands::CreateSettlement.new(
      room_id: room.id,
      actor_id: room.owner_id,
      payer_id: bob.id,
      payee_id: room.owner_id,
      amount_cents: 500,
      currency: "USD",
      note: "cash"
    )
  end

  it "creates settlement and publishes SettlementCompleted" do
    settlement = service.call(command)
    expect(settlement).to be_persisted
    expect(settlement.note).to eq("cash")

    events = Rails.configuration.x.domain_event_store.read.stream("Room$#{room.id}").to_a
    expect(events.last).to be_a(Settlements::Events::SettlementCompleted)
  end

  it "rejects payer equal to payee" do
    bad = command.with(payer_id: bob.id, payee_id: bob.id)
    expect { service.call(bad) }.to raise_error(ArgumentError, "payer and payee must differ")
  end

  it "rejects non-member payer" do
    outsider = create(:user)
    bad = command.with(payer_id: outsider.id)
    expect { service.call(bad) }.to raise_error(ArgumentError, "payer must be a member")
  end

  it "rejects non-positive amount" do
    bad = command.with(amount_cents: 0)
    expect { service.call(bad) }.to raise_error(ArgumentError, "amount must be positive")
  end
end
