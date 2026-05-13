# frozen_string_literal: true

class ExpensePolicy < ApplicationPolicy
  def create?
    member_of_room?(record.room)
  end

  def update?
    record.created_by_id == user.id && member_of_room?(record.room)
  end

  def destroy?
    update?
  end

  private

  def member_of_room?(room)
    room.memberships.exists?(user_id: user.id)
  end
end
