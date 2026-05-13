# frozen_string_literal: true

# Rails 8.1 + PostgreSQL: InsertAll / upsert_all need a resolvable unique index for ON CONFLICT.
# The PG adapter lists unique indexes with `indisprimary = false`, so the primary key is omitted.
# Solid Queue 1.4 calls `insert_all` without `unique_by`; ruby_event_store-active_record calls
# `upsert_all` without `unique_by` in EventRepository#update_messages. ActiveRecord then falls
# back to `model.primary_key` ("id") and can raise:
#   ArgumentError: No unique index found for id
# Passing an explicit `unique_by` hits the branch that synthesizes a primary-key index, or
# targets the `event_id` unique index on the event store table.

module SolidQueueJobBulkInsertUniqueBy
  def create_all_from_active_jobs(active_jobs)
    job_rows = active_jobs.map { |job| attributes_from_active_job(job) }
    insert_all(job_rows, unique_by: :id)
    where(active_job_id: active_jobs.map(&:job_id)).order(id: :asc)
  end
end

module SolidQueueExecutionBulkInsertUniqueBy
  def create_all_from_jobs(jobs)
    insert_all(execution_data_from_jobs(jobs), unique_by: :id)
  end
end

module RubyEventStoreActiveRecordEventRepositoryUpsertUniqueByEventId
  def update_messages(records)
    hashes = records.map { |record| upsert_hash(record, record.serialize(@serializer)) }
    for_update = records.map(&:event_id)
    start_transaction do
      existing =
        event_klass
          .where(event_id: for_update)
          .pluck(:event_id, :id, :created_at)
          .each_with_object({}) { |(event_id, id, created_at), acc| acc[event_id] = [ id, created_at ] }
      (for_update - existing.keys).each { |id| raise RubyEventStore::EventNotFound.new(id) }
      hashes.each do |h|
        h[:id] = existing.fetch(h.fetch(:event_id)).at(0)
        h[:created_at] = existing.fetch(h.fetch(:event_id)).at(1)
      end
      event_klass.upsert_all(hashes, unique_by: :event_id)
    end
  end
end

Rails.application.config.to_prepare do
  if defined?(SolidQueue::Job) && !SolidQueue::Job.instance_variable_defined?(:@_ddd_eds_bulk_insert_unique_by)
    SolidQueue::Job.singleton_class.prepend(SolidQueueJobBulkInsertUniqueBy)
    SolidQueue::Job.instance_variable_set(:@_ddd_eds_bulk_insert_unique_by, true)
  end

  if defined?(SolidQueue::Execution) && !SolidQueue::Execution.instance_variable_defined?(:@_ddd_eds_bulk_insert_unique_by)
    SolidQueue::Execution.singleton_class.prepend(SolidQueueExecutionBulkInsertUniqueBy)
    SolidQueue::Execution.instance_variable_set(:@_ddd_eds_bulk_insert_unique_by, true)
  end

  if defined?(RubyEventStore::ActiveRecord::EventRepository) &&
      !RubyEventStore::ActiveRecord::EventRepository.instance_variable_defined?(:@_ddd_eds_bulk_insert_unique_by)
    RubyEventStore::ActiveRecord::EventRepository.prepend(RubyEventStoreActiveRecordEventRepositoryUpsertUniqueByEventId)
    RubyEventStore::ActiveRecord::EventRepository.instance_variable_set(:@_ddd_eds_bulk_insert_unique_by, true)
  end
end
