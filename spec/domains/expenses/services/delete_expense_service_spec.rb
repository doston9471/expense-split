# frozen_string_literal: true

require "rails_helper"

RSpec.describe Expenses::Services::DeleteExpenseService, type: :model do
  let(:service) { described_class.new }
  let(:room) { create(:room) }
  let!(:expense) { create(:expense, room:, created_by: room.owner, participant_list: [ room.owner ]) }

  it "destroys expense and publishes ExpenseDeleted" do
    command = Expenses::Commands::DeleteExpense.new(expense_id: expense.id, actor_id: room.owner_id)
    expect { service.call(command) }.to change(Expense, :count).by(-1)

    events = Rails.configuration.x.domain_event_store.read.stream("Room$#{room.id}").to_a
    expect(events.last).to be_a(Expenses::Events::ExpenseDeleted)
  end

  it "rejects non-creator" do
    other = create(:user)
    create(:membership, room:, user: other, role: "member")
    command = Expenses::Commands::DeleteExpense.new(expense_id: expense.id, actor_id: other.id)
    expect { service.call(command) }.to raise_error(ArgumentError, "forbidden")
  end
end
