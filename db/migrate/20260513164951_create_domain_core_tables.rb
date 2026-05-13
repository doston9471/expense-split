# frozen_string_literal: true

class CreateDomainCoreTables < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string :name, null: false
      t.string :status, null: false, default: "active"
      t.string :invite_token, null: false
      t.datetime :archived_at
      t.timestamps
    end
    add_index :rooms, :invite_token, unique: true
    add_index :rooms, :status

    create_table :memberships, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: false
      t.references :room, null: false, foreign_key: true, type: :uuid, index: false
      t.string :role, null: false
      t.timestamps
    end
    add_index :memberships, [ :user_id, :room_id ], unique: true
    add_index :memberships, :room_id

    create_table :invitations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :room, null: false, foreign_key: true, type: :uuid
      t.references :invited_by, null: true, foreign_key: { to_table: :users }, type: :uuid
      t.string :email
      t.string :token, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :expires_at
      t.timestamps
    end
    add_index :invitations, :token, unique: true

    create_table :expenses, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :room, null: false, foreign_key: true, type: :uuid
      t.string :title, null: false
      t.bigint :amount_cents, null: false
      t.string :currency, null: false, default: "USD"
      t.references :paid_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :created_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string :split_type, null: false, default: "equal"
      t.timestamps
    end

    create_table :expense_participants, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :expense, null: false, foreign_key: true, type: :uuid, index: false
      t.references :user, null: false, foreign_key: true, type: :uuid, index: false
      t.bigint :allocation_cents
      t.timestamps
    end
    add_index :expense_participants, [ :expense_id, :user_id ], unique: true

    create_table :balances, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :room, null: false, foreign_key: true, type: :uuid, index: false
      t.references :creditor, null: false, foreign_key: { to_table: :users }, type: :uuid, index: false
      t.references :debtor, null: false, foreign_key: { to_table: :users }, type: :uuid, index: false
      t.bigint :amount_cents, null: false, default: 0
      t.string :currency, null: false, default: "USD"
      t.timestamps
    end
    add_index :balances, [ :room_id, :creditor_id, :debtor_id ], unique: true
    add_index :balances, :room_id

    create_table :settlements, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :room, null: false, foreign_key: true, type: :uuid, index: true
      t.references :payer, null: false, foreign_key: { to_table: :users }, type: :uuid, index: false
      t.references :payee, null: false, foreign_key: { to_table: :users }, type: :uuid, index: false
      t.bigint :amount_cents, null: false
      t.string :currency, null: false, default: "USD"
      t.string :note
      t.timestamps
    end
  end
end
