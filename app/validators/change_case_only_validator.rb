class ChangeCaseOnlyValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil? || record.send(:"#{attribute}_was").nil?
    # i18n-tasks-use t("activerecord.errors.models.model_file.attributes.filename.case_change_only")
    record.errors.add attribute, :case_change_only if record.send(:"#{attribute}_changed?") && value.downcase == record.send(:"#{attribute}_was").downcase
  end
end
