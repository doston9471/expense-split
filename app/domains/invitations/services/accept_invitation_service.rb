# frozen_string_literal: true

module Invitations
  module Services
    class AcceptInvitationService
      def initialize(
        invitations: Repositories::InvitationRepository.new,
        memberships: Memberships::Repositories::MembershipRepository.new,
        event_store: Rails.configuration.x.domain_event_store
      )
        @invitations = invitations
        @memberships = memberships
        @event_store = event_store
      end

      def call(command)
        invitation = ::Invitation.find_by(token: command.token)
        raise ArgumentError, "invitation not found" unless invitation
        raise ArgumentError, "invitation is no longer valid" unless invitation.usable?
        raise ArgumentError, "room is archived" if invitation.room.archived?

        user = User.find(command.user_id)
        if invitation.email.present? && invitation.email.downcase != user.email.downcase
          raise ArgumentError, "sign in with the invited email address to accept"
        end

        room = invitation.room

        ::ApplicationRecord.transaction do
          if @memberships.member?(room_id: room.id, user_id: user.id)
            @invitations.accept!(invitation, user:) if invitation.pending?
            publish_accepted!(room.id, invitation.id, user.id, already_member: true)
          else
            @memberships.create_member!(room_id: room.id, user_id: user.id)
            @invitations.accept!(invitation, user:)
            @event_store.publish(
              Memberships::Events::MemberJoined.new(
                data: {
                  room_id: room.id,
                  user_id: user.id,
                  via: "invitation",
                  invitation_id: invitation.id
                }
              ),
              stream_name: stream(room.id)
            )
            publish_accepted!(room.id, invitation.id, user.id, already_member: false)
          end
        end
        invitation.reload
      end

      private

      def publish_accepted!(room_id, invitation_id, user_id, already_member:)
        @event_store.publish(
          Events::InvitationAccepted.new(
            data: {
              room_id:,
              invitation_id:,
              user_id:,
              already_member:
            }
          ),
          stream_name: stream(room_id)
        )
      end

      def stream(room_id)
        "Room$#{room_id}"
      end
    end
  end
end
