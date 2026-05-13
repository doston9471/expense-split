# frozen_string_literal: true

module Rooms
  module Subscribers
    # Pushes a Turbo Stream +refresh+ to everyone subscribed to this room so they
    # pick up expenses, balances, invitations, and members without reloading manually.
    class BroadcastRoomRefresh
      def call(event)
        room_id = event.data.symbolize_keys[:room_id]
        return if room_id.blank?

        room = ::Room.find_by(id: room_id)
        return unless room

        Turbo::StreamsChannel.broadcast_refresh_to(room, :live)
      end
    end
  end
end
