# frozen_string_literal: true

class InvitationPolicy < ApplicationPolicy
  def create?
    user.present? && record.room.memberships.exists?(user_id: user.id)
  end

  def destroy?
    user.present? && (record.room.owner_id == user.id || record.invited_by_id == user.id)
  end
end
