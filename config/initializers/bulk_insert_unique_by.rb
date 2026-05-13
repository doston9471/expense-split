# frozen_string_literal: true

# Rails 8.1 + PostgreSQL: InsertAll#find_unique_index_for raises
#   ArgumentError: No unique index found for id
# when resolving ON CONFLICT targets. PostgreSQL's schema reflection omits primary-key
# indexes from `unique_indexes`, and `defined?(SolidQueue::Job)` does not trigger
# Zeitwerk autoload — so prepending Solid Queue at boot often never ran on Heroku.
#
# Fix: prepend ActiveRecord::InsertAll once and, on that specific error, supply either
# the real unique index on `event_id` (event store) or a synthetic PK index on `id`
# for `solid_queue_*` / `event_store_*` / `solid_cable_*` tables that expose an `id` column.

module DddEdsInsertAllUniqueIndexFallback
  def find_unique_index_for(unique_by)
    super
  rescue ArgumentError => e
    raise e unless e.message.start_with?("No unique index found for ")
    raise e unless connection.adapter_name == "PostgreSQL"

    name_or_columns = unique_by || model.primary_key
    match = Array(name_or_columns).map(&:to_s)

    if model.table_name.to_s == "event_store_events"
      idx = unique_indexes.find { |i| Array(i.columns).map(&:to_s) == [ "event_id" ] }
      return idx if idx
    end

    if synthetic_id_unique_index?(match)
      return ActiveRecord::ConnectionAdapters::IndexDefinition.new(
        model.table_name, "#{model.table_name}_primary_key", true, [ "id" ]
      )
    end

    raise e
  end

  # Only tables we own for this workaround. Do not call `columns_hash` here: for adapters like
  # Solid Cable, the table may not exist yet on Heroku (only `db:migrate` ran, not cable_schema),
  # and touching the schema cache raises PG::UndefinedTable and masks the original error.
  def synthetic_id_unique_index?(match)
    return false unless match == [ "id" ]

    t = model.table_name.to_s
    t.start_with?("solid_queue_") || t.start_with?("event_store_") || t.start_with?("solid_cable_")
  end
end

# InsertAll is not eager-autoloaded with ActiveRecord::Base; referencing it in after_initialize
# before anything calls insert_all raises NameError during e.g. `rake assets:precompile` on Heroku.
Rails.application.config.after_initialize do
  next unless defined?(ActiveRecord)

  require "active_record/insert_all"

  insert_all = ActiveRecord::InsertAll
  next if insert_all.instance_variable_defined?(:@_ddd_eds_insert_all_fallback)

  insert_all.prepend(DddEdsInsertAllUniqueIndexFallback)
  insert_all.instance_variable_set(:@_ddd_eds_insert_all_fallback, true)
end
