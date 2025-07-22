class Upgrade::BackfillImageDerivatives < ApplicationJob
  include JobIteration::Iteration
  queue_as :low
  unique :until_executed

  def build_enumerator(cursor:)
    enumerator_builder.active_record_on_records(
      ModelFile.unscoped.where.not("attachment_data LIKE '%derivatives%'").and(ModelFile.unscoped.where("attachment_data LIKE '%\"image/%'")),
      cursor: cursor
    )
  end

  def each_iteration(modelfile)
    Rails.logger.info("Creating image derivatives for: #{modelfile.path_within_library}")
    modelfile.attachment_derivatives!
    modelfile.save(touch: false, validate: false)
  rescue Shrine::FileNotFound
    Rails.logger.info("File not found: #{modelfile.path_within_library}")
  end
end
