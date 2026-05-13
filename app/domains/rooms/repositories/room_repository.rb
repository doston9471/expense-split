# frozen_string_literal: true

module Rooms
  module Repositories
    class RoomRepository
      def find(room_id)
        ::Room.find(room_id)
      end

      def find_by_invite_token!(token)
        ::Room.find_by!(invite_token: token)
      end

      def create!(owner_id:, name:, invite_token:)
        ::Room.create!(
          owner_id:,
          name:,
          invite_token:,
          status: "active"
        )
      end

      def archive!(room)
        room.update!(status: "archived", archived_at: Time.current)
      end
    end
  end
end
