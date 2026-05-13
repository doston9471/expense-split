# frozen_string_literal: true

class RoomJoinsController < ApplicationController
  skip_before_action :authenticate_user!, only: :show

  def show
    @token = params[:token]
  end

  def create
    Memberships::Services::JoinRoomService.new.call(
      Memberships::Commands::JoinRoom.new(invite_token: params[:token], user_id: current_user.id)
    )
    room = Rooms::Repositories::RoomRepository.new.find_by_invite_token!(params[:token])
    redirect_to room_path(room), notice: "You joined the room."
  rescue ArgumentError, ActiveRecord::RecordNotFound => e
    redirect_to join_room_path(params[:token]), alert: e.message
  end
end
