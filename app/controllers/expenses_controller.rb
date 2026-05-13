# frozen_string_literal: true

class ExpensesController < ApplicationController
  before_action :set_room

  def new
    @expense = Expense.new(room: @room, currency: "USD", split_type: "equal", paid_by: current_user)
    authorize @expense
  end

  def create
    @expense = Expense.new(room: @room)
    authorize @expense
    cents = MoneyHelpers.cents_from_decimal(expense_params[:amount])
    command = Expenses::Commands::CreateExpense.new(
      room_id: @room.id,
      actor_id: current_user.id,
      title: expense_params[:title].to_s.strip,
      amount_cents: cents,
      currency: expense_params[:currency].presence || "USD",
      paid_by_id: expense_params[:paid_by_id],
      split_type: "equal",
      participant_ids: Array(expense_params[:participant_ids]).compact_blank
    )
    Expenses::Services::CreateExpenseService.new.call(command)
    redirect_to room_path(@room), notice: "Expense recorded."
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_to new_room_expense_path(@room), alert: e.message
  end

  def edit
    @expense = @room.expenses.find(params[:id])
    authorize @expense
  end

  def update
    @expense = @room.expenses.find(params[:id])
    authorize @expense
    cents = MoneyHelpers.cents_from_decimal(expense_params[:amount])
    command = Expenses::Commands::UpdateExpense.new(
      expense_id: @expense.id,
      actor_id: current_user.id,
      title: expense_params[:title].to_s.strip,
      amount_cents: cents,
      currency: expense_params[:currency].presence || "USD",
      paid_by_id: expense_params[:paid_by_id],
      split_type: "equal",
      participant_ids: Array(expense_params[:participant_ids]).compact_blank
    )
    Expenses::Services::UpdateExpenseService.new.call(command)
    redirect_to room_path(@room), notice: "Expense updated."
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_to edit_room_expense_path(@room, @expense), alert: e.message
  end

  def destroy
    @expense = @room.expenses.find(params[:id])
    authorize @expense
    Expenses::Services::DeleteExpenseService.new.call(
      Expenses::Commands::DeleteExpense.new(expense_id: @expense.id, actor_id: current_user.id)
    )
    redirect_to room_path(@room), notice: "Expense removed."
  rescue ArgumentError => e
    redirect_to room_path(@room), alert: e.message
  end

  private

  def set_room
    @room = Room.find(params[:room_id])
  end

  def expense_params
    params.require(:expense).permit(:title, :amount, :currency, :paid_by_id, participant_ids: [])
  end
end
