class StableMimeTypeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if !record.persisted? || record.attachment.nil? || value.nil?
    # i18n-tasks-use t("activerecord.errors.models.model_file.attributes.filename.cannot_change_type")
    new_filename = record.attachment.metadata["filename"] || record.attachment.id
    if File.extname(new_filename).present? # If there's no extension, don't throw an error
      record.errors.add attribute, :cannot_change_type if mime(value) != mime(new_filename)
    end
  end

  def mime(value)
    Mime::EXTENSION_LOOKUP[File.extname(value).delete(".").downcase].to_s
  end
end
