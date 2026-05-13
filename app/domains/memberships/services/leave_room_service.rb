# frozen_string_literal: true

module Memberships
  module Services
    class LeaveRoomService
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
        room = @rooms.find(command.room_id)
        membership = @memberships.find_membership(room_id: room.id, user_id: command.user_id)
        raise ArgumentError, "not a member" unless membership
        raise ArgumentError, "owner cannot leave; archive the room or transfer ownership" if membership.role == "owner"

        ::ApplicationRecord.transaction do
          @memberships.destroy!(membership)
          @event_store.publish(
            Events::MemberLeft.new(data: { room_id: room.id, user_id: command.user_id }),
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
