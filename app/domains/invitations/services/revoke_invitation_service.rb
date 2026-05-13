# frozen_string_literal: true

module Invitations
  module Services
    class RevokeInvitationService
      def initialize(
        invitations: Repositories::InvitationRepository.new,
        event_store: Rails.configuration.x.domain_event_store
      )
        @invitations = invitations
        @event_store = event_store
      end

      def call(command)
        invitation = @invitations.find(command.invitation_id)
        raise ArgumentError, "invitation cannot be revoked" unless invitation.status == "pending"
        unless invitation.room.owner_id == command.actor_id || invitation.invited_by_id == command.actor_id
          raise ArgumentError, "forbidden"
        end

        ::ApplicationRecord.transaction do
          @invitations.revoke!(invitation)
          @event_store.publish(
            Events::InvitationRevoked.new(
              data: {
                room_id: invitation.room_id,
                invitation_id: invitation.id,
                actor_id: command.actor_id
              }
            ),
            stream_name: stream(invitation.room_id)
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
