# frozen_string_literal: true

module Invitations
  module Services
    class CreateInvitationService
      def initialize(
        rooms: Rooms::Repositories::RoomRepository.new,
        invitations: Repositories::InvitationRepository.new,
        eligibility: Policies::InvitationEligibilityPolicy.new,
        event_store: Rails.configuration.x.domain_event_store
      )
        @rooms = rooms
        @invitations = invitations
        @eligibility = eligibility
        @event_store = event_store
      end

      def call(command)
        room = @rooms.find(command.room_id)
        @eligibility.validate_room_active!(room)
        @eligibility.validate_inviter_member!(room_id: room.id, user_id: command.invited_by_id)
        @eligibility.validate_email!(command.email.to_s)

        ::ApplicationRecord.transaction do
          invitation = @invitations.create!(
            room:,
            invited_by_id: command.invited_by_id,
            email: command.email.to_s.presence,
            token: SecureRandom.urlsafe_base64(32),
            status: "pending",
            expires_at: Time.current + Invitations::Policies::InvitationEligibilityPolicy::DEFAULT_TTL
          )

          @event_store.publish(
            Events::InvitationCreated.new(
              data: {
                room_id: room.id,
                invitation_id: invitation.id,
                email: invitation.email,
                invited_by_id: command.invited_by_id,
                expires_at: invitation.expires_at.iso8601
              }
            ),
            stream_name: stream(room.id)
          )
          invitation
        end
      end

      private

      def stream(room_id)
        "Room$#{room_id}"
      end
    end
  end
end
