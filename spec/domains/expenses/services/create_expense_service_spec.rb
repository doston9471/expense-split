# frozen_string_literal: true

require "rails_helper"

RSpec.describe Expenses::Services::CreateExpenseService, type: :model do
  let(:service) { described_class.new }
  let(:room) { create(:room) }
  let(:bob) { create(:user) }

  before { create(:membership, room:, user: bob, role: "member") }

  let(:command) do
    Expenses::Commands::CreateExpense.new(
      room_id: room.id,
      actor_id: room.owner_id,
      title: "Dinner",
      amount_cents: 3000,
      currency: "USD",
      paid_by_id: room.owner_id,
      split_type: "equal",
      participant_ids: [ room.owner_id, bob.id ]
    )
  end

  it "creates expense with participants and publishes ExpenseCreated" do
    expense = service.call(command)
    expect(expense).to be_persisted
    expect(expense.expense_participants.count).to eq(2)

    events = Rails.configuration.x.domain_event_store.read.stream("Room$#{room.id}").to_a
    expect(events.last).to be_a(Expenses::Events::ExpenseCreated)
  end

  it "rejects non-equal split" do
    bad = Expenses::Commands::CreateExpense.new(
      room_id: room.id,
      actor_id: room.owner_id,
      title: "X",
      amount_cents: 100,
      currency: "USD",
      paid_by_id: room.owner_id,
      split_type: "percentage",
      participant_ids: [ room.owner_id ]
    )
    expect { service.call(bad) }.to raise_error(ArgumentError, "only equal split is implemented")
  end

  it "rejects payer not in room" do
    outsider = create(:user)
    bad = command.with(paid_by_id: outsider.id)
    expect { service.call(bad) }.to raise_error(ArgumentError, "payer must be a room member")
  end
end
