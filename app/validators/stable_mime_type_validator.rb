class StableMimeTypeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if record.attachment.nil? || value.nil?
    # i18n-tasks-use t("activerecord.errors.models.model_file.attributes.filename.cannot_change_type")
    record.errors.add attribute, :cannot_change_type if mime(value) != mime(record.attachment.id)
  end

  def mime(value)
    Mime::EXTENSION_LOOKUP[File.extname(value).delete(".").downcase].to_s
  end
end
