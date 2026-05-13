# frozen_string_literal: true

require "rails_helper"

RSpec.describe Expenses::Repositories::ExpenseRepository, type: :model do
  subject(:repo) { described_class.new }

  let(:room) { create(:room) }
  let(:bob) { create(:user) }

  before { create(:membership, room:, user: bob, role: "member") }

  it "#create_with_participants! creates expense and rows" do
    expense = repo.create_with_participants!(
      {
        room_id: room.id,
        title: "Lunch",
        amount_cents: 900,
        currency: "USD",
        paid_by_id: room.owner_id,
        created_by_id: room.owner_id,
        split_type: "equal"
      },
      [ room.owner_id, bob.id ]
    )
    expect(expense.expense_participants.count).to eq(2)
  end

  it "#replace_participants! swaps participants" do
    expense = create(:expense, room:, participant_list: [ room.owner ])
    repo.replace_participants!(expense, [ room.owner_id, bob.id ])
    expect(expense.reload.participant_ids).to contain_exactly(room.owner_id, bob.id)
  end

  it "#update! and #destroy!" do
    expense = create(:expense, room:, participant_list: [ room.owner ])
    repo.update!(expense, title: "Renamed")
    expect(expense.reload.title).to eq("Renamed")
    repo.destroy!(expense)
    expect(Expense.find_by(id: expense.id)).to be_nil
  end
end
