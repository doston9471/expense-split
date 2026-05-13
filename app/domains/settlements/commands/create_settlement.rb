# frozen_string_literal: true

module Settlements
  module Commands
    CreateSettlement = Data.define(
      :room_id,
      :actor_id,
      :payer_id,
      :payee_id,
      :amount_cents,
      :currency,
      :note
    )
  end
end
