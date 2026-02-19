class Upgrade::BackfillDerivativesBase < Upgrade::FileTypeIterationJob
  def derivative
    raise NotImplementedError
  end

  def scope
    super.where(
      DatabaseDetector.is_postgres? ?
        "json_extract_path(attachment_data, 'derivatives', '#{derivative}') IS NULL" :
        "json_extract(attachment_data, '$.derivatives.#{derivative}') IS NULL"
    )
  end

  def apply(modelfile)
    Rails.logger.info("Creating derivatives for: #{modelfile.path_within_library}")
    modelfile.attachment_derivatives!
    modelfile.save(touch: false, validate: false)
  end
end
