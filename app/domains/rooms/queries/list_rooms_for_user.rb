# frozen_string_literal: true

module Rooms
  module Queries
    class ListRoomsForUser
      def call(user_id:)
        ::Room
          .joins(:memberships)
          .where(memberships: { user_id: })
          .merge(::Room.active)
          .order(:name)
          .distinct
      end
    end
  end
end
