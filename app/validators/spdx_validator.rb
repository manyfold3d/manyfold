class SpdxValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # i18n-tasks-use t("activerecord.errors.models.model.attributes.license.invalid_spdx")
    record.errors.add attribute, :invalid_spdx if !Spdx.valid?(value)
  end
end
