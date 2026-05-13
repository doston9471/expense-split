# frozen_string_literal: true

# Tracked invite (email-scoped or open link). Distinct from `Room#invite_token`:
# invitations can expire, be revoked, and optionally require a matching email at accept time.
class Invitation < ApplicationRecord
  STATUSES = %w[pending accepted revoked expired].freeze

  belongs_to :room
  belongs_to :invited_by, class_name: "User", optional: true
  belongs_to :accepted_by, class_name: "User", optional: true

  validates :token, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }

  scope :pending, -> { where(status: "pending") }
  scope :open, -> { pending.where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def usable?
    status == "pending" && !expired?
  end

  def pending?
    status == "pending"
  end
end
