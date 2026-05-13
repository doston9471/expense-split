# frozen_string_literal: true

module Invitations
  module Repositories
    class InvitationRepository
      def find(id)
        ::Invitation.find(id)
      end

      def find_by_token!(token)
        ::Invitation.find_by!(token:)
      end

      def create!(attrs)
        ::Invitation.create!(attrs)
      end

      def revoke!(invitation)
        invitation.update!(status: "revoked")
      end

      def accept!(invitation, user:)
        invitation.update!(status: "accepted", accepted_by: user, accepted_at: Time.current)
      end
    end
  end
end
