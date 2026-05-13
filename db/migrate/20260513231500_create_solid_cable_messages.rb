# frozen_string_literal: true

# Solid Cable stores Action Cable payloads in PostgreSQL (see config/cable.yml production).
# With a single Heroku DATABASE_URL, `db:migrate` only applies db/migrate — not db/cable_schema.rb.
# Turbo broadcasts (e.g. after MemberJoined) hit Action Cable and require this table.
class CreateSolidCableMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :solid_cable_messages, if_not_exists: true do |t|
      t.binary :channel, limit: 1024, null: false
      t.binary :payload, limit: 536_870_912, null: false
      t.datetime :created_at, null: false
      t.bigint :channel_hash, null: false
    end

    add_index :solid_cable_messages, :channel,
      name: "index_solid_cable_messages_on_channel",
      if_not_exists: true
    add_index :solid_cable_messages, :channel_hash,
      name: "index_solid_cable_messages_on_channel_hash",
      if_not_exists: true
    add_index :solid_cable_messages, :created_at,
      name: "index_solid_cable_messages_on_created_at",
      if_not_exists: true
  end
end
