# frozen_string_literal: true

require "rails_helper"

RSpec.describe Balances::Subscribers::RebuildBalances, type: :model do
  subject(:subscriber) { described_class.new }

  describe "#call" do
    it "rebuilds balances idempotently from expenses" do
      alice = create(:user, display_name: "Alice")
      room = create(:room, owner: alice)
      bob = create(:user, display_name: "Bob")
      carol = create(:user, display_name: "Carol")
      create(:membership, room:, user: bob, role: "member")
      create(:membership, room:, user: carol, role: "member")

      create(
        :expense,
        room:,
        paid_by: alice,
        created_by: alice,
        amount_cents: 600,
        participant_list: [ alice, bob, carol ]
      )

      event = Expenses::Events::ExpenseCreated.new(data: { room_id: room.id })
      subscriber.call(event)

      expect(Balance.find_by!(room:, debtor: bob, creditor: alice).amount_cents).to eq(200)
      expect(Balance.find_by!(room:, debtor: carol, creditor: alice).amount_cents).to eq(200)

      subscriber.call(event)
      expect(Balance.where(room:).count).to eq(2)
    end

    it "reacts to ExpenseUpdated" do
      room = create(:room)
      bob = create(:user)
      create(:membership, room:, user: bob, role: "member")
      expense = create(
        :expense,
        room:,
        paid_by: room.owner,
        created_by: room.owner,
        amount_cents: 200,
        participant_list: [ room.owner, bob ]
      )

      Balances::Services::RebuildRoomBalances.call(room_id: room.id)
      expect(Balance.find_by!(room:, debtor: bob, creditor: room.owner).amount_cents).to eq(100)

      expense.update!(amount_cents: 400)
      subscriber.call(
        Expenses::Events::ExpenseUpdated.new(data: { room_id: room.id, expense_id: expense.id })
      )

      expect(Balance.find_by!(room:, debtor: bob, creditor: room.owner).amount_cents).to eq(200)
    end

    it "reacts to SettlementCompleted" do
      room = create(:room)
      bob = create(:user)
      create(:membership, room:, user: bob, role: "member")
      create(
        :expense,
        room:,
        paid_by: room.owner,
        created_by: room.owner,
        amount_cents: 200,
        participant_list: [ room.owner, bob ]
      )
      create(:settlement, room:, payer: bob, payee: room.owner, amount_cents: 100)

      subscriber.call(Settlements::Events::SettlementCompleted.new(data: { room_id: room.id }))

      expect(Balance.find_by(room:, debtor: bob, creditor: room.owner)).to be_nil
    end
  end
end
