# frozen_string_literal: true

class RoomPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    member?
  end

  def create?
    user.present?
  end

  def archive?
    owner?
  end

  def leave?
    member?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:memberships).where(memberships: { user_id: user.id }).distinct
    end
  end

  private

  def member?
    record.memberships.exists?(user_id: user.id)
  end

  def owner?
    record.owner_id == user.id
  end
end
