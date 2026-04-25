# frozen_string_literal: true

class Upgrade::ConvertCollectionsJob < Upgrade::IterationJob
  queue_as :upgrade

  def build_enumerator(cursor:)
    # Find models that have something in the old collection field
    enumerator_builder.active_record_on_records(Model.where.not(collection_id: nil), cursor: cursor)
  end

  def each_iteration(record)
    collection = Collection.find(record.collection_id)
    # Add to the new association
    record.collections << collection unless record.collections.include?(collection)
    # Remove the old collection ID without validation, callbacks, or touching the date
    record.update_column :collection_id, nil # rubocop:disable Rails/SkipsModelValidations
  end
end
