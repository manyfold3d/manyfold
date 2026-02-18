class Upgrade::BackfillDerivativesBase < ApplicationJob
  include JobIteration::Iteration

  unique :until_executed

  def scope
    mime_type_clause = case DatabaseDetector.server
    when :postgresql
      "json_extract_path_text(attachment_data, 'metadata', 'mime_type') IN (?)"
    when :mysql
      "json_value(attachment_data, '$.metadata.mime_type') IN (?)"
    when :sqlite
      "json_extract(attachment_data, '$.metadata.mime_type') IN (?)"
    else
      raise NotImplementedError.new("Unknown database adapter #{DatabaseDetector.server}")
    end
    ModelFile.unscoped.where(mime_type_clause, mime_types.map(&:to_s))
      .where(
        DatabaseDetector.is_postgres? ?
          "json_extract_path(attachment_data, 'derivatives', '#{derivative}') IS NULL" :
          "json_extract(attachment_data, '$.derivatives.#{derivative}') IS NULL"
      )
  end

  def build_enumerator(cursor:)
    enumerator_builder.active_record_on_records(scope, cursor: cursor)
  end

  def each_iteration(modelfile)
    Rails.logger.info("Creating derivatives for: #{modelfile.path_within_library}")
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
