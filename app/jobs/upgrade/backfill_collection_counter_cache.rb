# frozen_string_literal: true

class Upgrade::BackfillCollectionCounterCache < Upgrade::IterationJob
  queue_as :low
  unique :until_executed

  def build_enumerator(cursor:)
    # Find models that have something in the old collection field
    enumerator_builder.active_record_on_records(Collection.where(models_count: nil), cursor: cursor)
  end

  def each_iteration(record)
    Collection.reset_counters(record.id, :models)
  end
end
