# frozen_string_literal: true

require "rails_helper"

RSpec.describe Balances::Services::RebuildRoomBalances, type: :model do
  it "consolidates debts to minimum cash flow while preserving each person's net" do
    john = create(:user, display_name: "john")
    doston = create(:user, display_name: "doston")
    testuser = create(:user, display_name: "testuser")
    room = create(:room, owner: john)
    create(:membership, room:, user: doston, role: "member")
    create(:membership, room:, user: testuser, role: "member")

    create(
      :expense,
      room:,
      paid_by: doston,
      created_by: doston,
      title: "lunch",
      amount_cents: 10_000,
      participant_list: [ doston, testuser ]
    )
    create(
      :expense,
      room:,
      paid_by: john,
      created_by: john,
      title: "cinema",
      amount_cents: 60_000,
      participant_list: [ john, doston, testuser ]
    )

    described_class.call(room_id: room.id)

    expect(Balance.where(room:).count).to eq(2)
    expect(Balance.find_by!(room:, debtor: testuser, creditor: john).amount_cents).to eq(25_000)
    expect(Balance.find_by!(room:, debtor: doston, creditor: john).amount_cents).to eq(15_000)
    expect(Balance.find_by(room:, debtor: testuser, creditor: doston)).to be_nil
  end

  it "nets cyclic debts to zero edges" do
    a = create(:user, display_name: "A")
    b = create(:user, display_name: "B")
    c = create(:user, display_name: "C")
    room = create(:room, owner: a)
    create(:membership, room:, user: b, role: "member")
    create(:membership, room:, user: c, role: "member")

    create(:expense, room:, paid_by: a, created_by: a, amount_cents: 30, participant_list: [ a, b ])
    create(:expense, room:, paid_by: b, created_by: b, amount_cents: 30, participant_list: [ b, c ])
    create(:expense, room:, paid_by: c, created_by: c, amount_cents: 30, participant_list: [ c, a ])

    described_class.call(room_id: room.id)

    expect(Balance.where(room:)).to be_empty
  end

  it "applies settlements after expenses" do
    room = create(:room)
    alice = create(:user, display_name: "Alice")
    bob = create(:user, display_name: "Bob")
    create(:membership, room:, user: alice, role: "member")
    create(:membership, room:, user: bob, role: "member")

    create(
      :expense,
      room:,
      paid_by: alice,
      created_by: alice,
      amount_cents: 100,
      participant_list: [ alice, bob ]
    )

    Settlement.create!(room:, payer: bob, payee: alice, amount_cents: 50, currency: "USD")

    described_class.call(room_id: room.id)

    # Net zero: projection omits rows with amount_cents <= 0
    expect(Balance.find_by(room:, debtor: bob, creditor: alice)).to be_nil
  end
end
