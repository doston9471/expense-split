# frozen_string_literal: true

class AddAcceptanceToInvitations < ActiveRecord::Migration[8.1]
  def change
    add_reference :invitations, :accepted_by, null: true, foreign_key: { to_table: :users }, type: :uuid, index: true
    add_column :invitations, :accepted_at, :datetime
  end
end
