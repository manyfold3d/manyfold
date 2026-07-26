# frozen_string_literal: true

class Upgrade::BackfillDataPackages < Upgrade::IterationJob
  queue_as :low
  unique :until_executed

  def build_enumerator(cursor:)
    enumerator_builder.active_record_on_records(Model.where.not(
      id: ModelFile.where(filename: "datapackage.json").select(:model_id)
    ), cursor: cursor)
  end

  def each_iteration(model)
    Model.suppressing_turbo_broadcasts { model.write_datapackage_later }
  end
end
