# frozen_string_literal: true

module Rooms
  module Services
    class CreateRoomService
      def initialize(
        rooms: Repositories::RoomRepository.new,
        memberships: Memberships::Repositories::MembershipRepository.new,
        event_store: Rails.configuration.x.domain_event_store
      )
        @rooms = rooms
        @memberships = memberships
        @event_store = event_store
      end

      def call(command)
        ::ApplicationRecord.transaction do
          invite_token = SecureRandom.urlsafe_base64(24)
          room = @rooms.create!(owner_id: command.owner_id, name: command.name, invite_token:)
          @memberships.create_owner!(room_id: room.id, user_id: command.owner_id)

          @event_store.publish(
            Events::RoomCreated.new(
              data: {
                room_id: room.id,
                owner_id: command.owner_id,
                name: room.name,
                invite_token: room.invite_token
              }
            ),
            stream_name: stream(room.id)
          )
          room
        end
      end

      private

      def stream(room_id)
        "Room$#{room_id}"
      end
    end
  end
end
