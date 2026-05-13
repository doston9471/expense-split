# frozen_string_literal: true

require "rails_helper"

RSpec.describe Expenses::Services::UpdateExpenseService, type: :model do
  let(:service) { described_class.new }
  let(:room) { create(:room) }
  let(:bob) { create(:user) }

  before { create(:membership, room:, user: bob, role: "member") }

  let!(:expense) do
    create(
      :expense,
      room:,
      paid_by: room.owner,
      created_by: room.owner,
      amount_cents: 1000,
      participant_list: [ room.owner, bob ]
    )
  end

  let(:command) do
    Expenses::Commands::UpdateExpense.new(
      expense_id: expense.id,
      actor_id: room.owner_id,
      title: "Updated",
      amount_cents: 2000,
      currency: "USD",
      paid_by_id: bob.id,
      split_type: "equal",
      participant_ids: [ room.owner_id, bob.id ]
    )
  end

  it "updates expense and publishes ExpenseUpdated" do
    updated = service.call(command)
    expect(updated.reload.title).to eq("Updated")
    expect(updated.amount_cents).to eq(2000)
    expect(updated.paid_by_id).to eq(bob.id)

    events = Rails.configuration.x.domain_event_store.read.stream("Room$#{room.id}").to_a
    expect(events.last).to be_a(Expenses::Events::ExpenseUpdated)
  end

  it "rejects non-creator" do
    bad = command.with(actor_id: bob.id)
    expect { service.call(bad) }.to raise_error(ArgumentError, "forbidden")
  end
end
