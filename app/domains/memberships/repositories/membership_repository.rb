# frozen_string_literal: true

module Memberships
  module Repositories
    class MembershipRepository
      def member?(room_id:, user_id:)
        ::Membership.exists?(room_id:, user_id:)
      end

      def find_membership(room_id:, user_id:)
        ::Membership.find_by(room_id:, user_id:)
      end

      def create_owner!(room_id:, user_id:)
        ::Membership.create!(room_id:, user_id:, role: "owner")
      end

      def create_member!(room_id:, user_id:)
        ::Membership.create!(room_id:, user_id:, role: "member")
      end

      def destroy!(membership)
        membership.destroy!
      end

      def room_member_ids(room_id)
        ::Membership.where(room_id:).pluck(:user_id)
      end
    end
  end
end
