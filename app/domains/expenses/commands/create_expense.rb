# frozen_string_literal: true

module Expenses
  module Commands
    CreateExpense = Data.define(
      :room_id,
      :actor_id,
      :title,
      :amount_cents,
      :currency,
      :paid_by_id,
      :split_type,
      :participant_ids
    )
  end
end
