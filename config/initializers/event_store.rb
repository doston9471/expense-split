# frozen_string_literal: true

# Single process-wide Rails Event Store client (PostgreSQL-backed via
# `rails_event_store_active_record`). Handlers run synchronously on publish by
# default; swapping the dispatcher later maps cleanly to an async bus or outbox.
Rails.application.config.after_initialize do
  # Do not use `config.x.event_store`: Rails treats `event_store` as a nested
  # namespace (truthy OrderedOptions), so `||=` never assigns the client.
  Rails.configuration.x.domain_event_store = RailsEventStore::Client.new

  store = Rails.configuration.x.domain_event_store
  store.subscribe(
    Balances::Subscribers::RebuildBalances.new,
    to: [
      Expenses::Events::ExpenseCreated,
      Expenses::Events::ExpenseUpdated,
      Expenses::Events::ExpenseDeleted,
      Settlements::Events::SettlementCompleted
    ]
  )

  store.subscribe(
    Rooms::Subscribers::BroadcastRoomRefresh.new,
    to: [
      Expenses::Events::ExpenseCreated,
      Expenses::Events::ExpenseUpdated,
      Expenses::Events::ExpenseDeleted,
      Settlements::Events::SettlementCompleted,
      Invitations::Events::InvitationCreated,
      Invitations::Events::InvitationRevoked,
      Invitations::Events::InvitationAccepted,
      Memberships::Events::MemberJoined,
      Memberships::Events::MemberLeft,
      Rooms::Events::RoomArchived
    ]
  )
end
