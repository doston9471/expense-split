# frozen_string_literal: true

module Invitations
  module Policies
    class InvitationEligibilityPolicy
      DEFAULT_TTL = 14.days

      def validate_room_active!(room)
        raise ArgumentError, "room is archived" if room.archived?
      end

      def validate_inviter_member!(room_id:, user_id:)
        unless Memberships::Repositories::MembershipRepository.new.member?(room_id:, user_id:)
          raise ArgumentError, "only room members can invite"
        end
      end

      def validate_email!(email)
        return if email.blank?

        raise ArgumentError, "invalid email" unless email.match?(URI::MailTo::EMAIL_REGEXP)
      end
    end
  end
end
