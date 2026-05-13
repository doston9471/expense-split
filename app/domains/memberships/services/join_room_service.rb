# frozen_string_literal: true

module Memberships
  module Services
    class JoinRoomService
      def initialize(
        rooms: Rooms::Repositories::RoomRepository.new,
        memberships: Repositories::MembershipRepository.new,
        event_store: Rails.configuration.x.domain_event_store
      )
        @rooms = rooms
        @memberships = memberships
        @event_store = event_store
      end

      def call(command)
        room = @rooms.find_by_invite_token!(command.invite_token)
        raise ArgumentError, "room is archived" if room.archived?
        if @memberships.member?(room_id: room.id, user_id: command.user_id)
          raise ArgumentError, "already a member"
        end

        ::ApplicationRecord.transaction do
          @memberships.create_member!(room_id: room.id, user_id: command.user_id)
          @event_store.publish(
            Events::MemberJoined.new(
              data: {
                room_id: room.id,
                user_id: command.user_id,
                invite_token: command.invite_token
              }
            ),
            stream_name: stream(room.id)
          )
        end
      end

      private

      def stream(room_id)
        "Room$#{room_id}"
      end
    end
  end
end
