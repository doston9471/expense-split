# frozen_string_literal: true

class SettlementPolicy < ApplicationPolicy
  def create?
    record.memberships.exists?(user_id: user.id)
  end
end
