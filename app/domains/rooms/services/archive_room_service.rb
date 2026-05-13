# frozen_string_literal: true

module Rooms
  module Services
    class ArchiveRoomService
      def initialize(
        rooms: Repositories::RoomRepository.new,
        event_store: Rails.configuration.x.domain_event_store
      )
        @rooms = rooms
        @event_store = event_store
      end

      def call(command)
        room = @rooms.find(command.room_id)
        raise ArgumentError, "only the room owner can archive" unless room.owner_id == command.actor_id
        raise ArgumentError, "room already archived" if room.archived?

        ::ApplicationRecord.transaction do
          @rooms.archive!(room)
          @event_store.publish(
            Events::RoomArchived.new(data: { room_id: room.id, actor_id: command.actor_id }),
            stream_name: stream(room.id)
          )
        end
        room.reload
      end

      private

      def stream(room_id)
        "Room$#{room_id}"
      end
    end
  end
end
