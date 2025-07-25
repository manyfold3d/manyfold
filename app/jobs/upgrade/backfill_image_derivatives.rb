class Upgrade::BackfillImageDerivatives < ApplicationJob
  include JobIteration::Iteration
  queue_as :low
  unique :until_executed

  def build_enumerator(cursor:)
    method = ((ApplicationRecord.connection.adapter_name == "PostgreSQL") ? "json_extract_path" : "json_extract")
    enumerator_builder.active_record_on_records(
      ModelFile.unscoped.where("#{method}(attachment_data, '$.derivatives', '$.preview') IS NULL"),
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
