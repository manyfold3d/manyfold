# frozen_string_literal: true

class Upgrade::ConvertSupportedRelationshipsJob < Upgrade::IterationJob
  queue_as :upgrade

  def build_enumerator(cursor:)
    # Find models that have something in the old presupported version field
    enumerator_builder.active_record_on_records(ModelFile.where.not(presupported_version_id: nil), cursor: cursor)
  end

  def each_iteration(record)
    record.reverse_relationships.find_or_create_by(
      subject_type: "ModelFile",
      subject_id: record.presupported_version_id,
      predicate: "supported_version_of"
    )
    # Remove the old collection ID without validation, callbacks, or touching the date
    record.update_column :presupported_version_id, nil # rubocop:disable Rails/SkipsModelValidations
  end
end
