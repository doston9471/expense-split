# frozen_string_literal: true

module Rooms
  class InvitationsController < ApplicationController
    before_action :set_room

    def create
      authorize Invitation.new(room: @room), :create?, policy_class: InvitationPolicy

      Invitations::Services::CreateInvitationService.new.call(
        Invitations::Commands::CreateInvitation.new(
          room_id: @room.id,
          invited_by_id: current_user.id,
          email: params.dig(:invitation, :email)
        )
      )
      redirect_to room_path(@room), notice: "Invitation link created."
    rescue ArgumentError => e
      redirect_to room_path(@room), alert: e.message
    end

    def destroy
      invitation = @room.invitations.find(params[:id])
      authorize invitation, :destroy?, policy_class: InvitationPolicy

      Invitations::Services::RevokeInvitationService.new.call(
        Invitations::Commands::RevokeInvitation.new(
          invitation_id: invitation.id,
          actor_id: current_user.id
        )
      )
      redirect_to room_path(@room), notice: "Invitation revoked."
    rescue ArgumentError => e
      redirect_to room_path(@room), alert: e.message
    end

    private

    def set_room
      @room = Room.find(params[:room_id])
    end
  end
end
