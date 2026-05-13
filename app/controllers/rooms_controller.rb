# frozen_string_literal: true

class RoomsController < ApplicationController
  def index
    authorize Room
    @rooms = Rooms::Queries::ListRoomsForUser.new.call(user_id: current_user.id)
  end

  def show
    @room = Room.find(params[:id])
    authorize @room
    @expenses = @room.expenses.includes(:paid_by, :expense_participants, :participants).order(created_at: :desc)
    @balances = @room.balances.includes(:debtor, :creditor).where("amount_cents > 0").order(amount_cents: :desc)
    @settlements = @room.settlements.includes(:payer, :payee).order(created_at: :desc).limit(30)
    @invitations = @room.invitations.open.includes(:invited_by, :accepted_by).order(created_at: :desc)
  end

  def new
    @room = Room.new
    authorize @room
  end

  def create
    authorize Room.new
    command = Rooms::Commands::CreateRoom.new(owner_id: current_user.id, name: room_params[:name].to_s.strip)
    room = Rooms::Services::CreateRoomService.new.call(command)
    redirect_to room_path(room), notice: "Room created."
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    flash[:alert] = e.message
    redirect_to new_room_path
  end

  def archive
    @room = Room.find(params[:id])
    authorize @room, :archive?
    Rooms::Services::ArchiveRoomService.new.call(
      Rooms::Commands::ArchiveRoom.new(room_id: @room.id, actor_id: current_user.id)
    )
    redirect_to rooms_path, notice: "Room archived."
  rescue ArgumentError => e
    redirect_to room_path(@room), alert: e.message
  end

  def leave
    @room = Room.find(params[:id])
    authorize @room, :leave?
    Memberships::Services::LeaveRoomService.new.call(
      Memberships::Commands::LeaveRoom.new(room_id: @room.id, user_id: current_user.id)
    )
    redirect_to rooms_path, notice: "You left the room."
  rescue ArgumentError => e
    redirect_to room_path(@room), alert: e.message
  end

  private

  def room_params
    params.require(:room).permit(:name)
  end
end
