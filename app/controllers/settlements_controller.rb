# frozen_string_literal: true

class SettlementsController < ApplicationController
  before_action :set_room

  def new
    authorize @room, :create?, policy_class: SettlementPolicy
    @settlement = Settlement.new(room: @room, currency: "USD")
  end

  def create
    authorize @room, :create?, policy_class: SettlementPolicy
    cents = MoneyHelpers.cents_from_decimal(settlement_params[:amount])
    command = Settlements::Commands::CreateSettlement.new(
      room_id: @room.id,
      actor_id: current_user.id,
      payer_id: settlement_params[:payer_id],
      payee_id: settlement_params[:payee_id],
      amount_cents: cents,
      currency: settlement_params[:currency].presence || "USD",
      note: settlement_params[:note].presence
    )
    Settlements::Services::CreateSettlementService.new.call(command)
    redirect_to room_path(@room), notice: "Settlement recorded."
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_to new_room_settlement_path(@room), alert: e.message
  end

  private

  def set_room
    @room = Room.find(params[:room_id])
  end

  def settlement_params
    params.require(:settlement).permit(:payer_id, :payee_id, :amount, :currency, :note)
  end
end
