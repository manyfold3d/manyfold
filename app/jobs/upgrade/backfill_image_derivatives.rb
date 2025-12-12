class Upgrade::BackfillImageDerivatives < ApplicationJob
  include JobIteration::Iteration

  queue_as :low
  unique :until_executed

  def scope
    method = ((ApplicationRecord.connection.adapter_name == "PostgreSQL") ? "json_extract_path" : "json_extract")
    ModelFile.unscoped.where("#{method}(attachment_data, '$.derivatives', '$.preview') IS NULL")
  end

  def build_enumerator(cursor:)
    enumerator_builder.active_record_on_records(scope, cursor: cursor)
  end

  def each_iteration(modelfile)
    return unless modelfile.is_image?
    Rails.logger.info("Creating image derivatives for: #{modelfile.path_within_library}")
    modelfile.attachment_derivatives!
    modelfile.save(touch: false, validate: false)
  rescue Errno::EACCES => ex
    Rails.logger.error ex.message
  rescue Shrine::FileNotFound
    Rails.logger.error("File not found: #{modelfile.path_within_library}")
  rescue Shrine::Error => ex
    Rails.logger.error("File error: #{ex.message} #{modelfile.path_within_library}")
  rescue MiniMagick::Error => ex
    Rails.logger.error ex.message
  end
end
