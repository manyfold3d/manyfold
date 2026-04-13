class ExistingPathValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # i18n-tasks-use t("activerecord.errors.models.library.attributes.path.not_found")
    record.errors.add attribute, :not_found if value.nil? || !File.exist?(value)
  end
end
