# frozen_string_literal: true

module Balances
  module Subscribers
    class RebuildBalances
      def call(event)
        room_id = event.data.symbolize_keys.fetch(:room_id)
        Balances::Services::RebuildRoomBalances.call(room_id:)
      end
    end
  end
end
