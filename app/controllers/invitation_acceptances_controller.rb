# frozen_string_literal: true

class InvitationAcceptancesController < ApplicationController
  skip_before_action :authenticate_user!, only: :show

  def show
    @invitation = Invitation.find_by(token: params[:token])
    return if @invitation&.usable?

    redirect_to root_path, alert: "This invitation is invalid or has expired."
  end

  def create
    invitation = Invitations::Services::AcceptInvitationService.new.call(
      Invitations::Commands::AcceptInvitation.new(
        token: params[:token],
        user_id: current_user.id
      )
    )
    redirect_to room_path(invitation.room), notice: "Welcome to the room."
  rescue ArgumentError => e
    redirect_to invitation_path(params[:token]), alert: e.message
  end
end
