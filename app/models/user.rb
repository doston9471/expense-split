# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :memberships, dependent: :destroy
  has_many :rooms, through: :memberships
  has_many :owned_rooms, class_name: "Room", foreign_key: :owner_id, inverse_of: :owner, dependent: :destroy

  validates :display_name, presence: true, length: { maximum: 120 }
end
