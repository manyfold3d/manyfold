class SpdxValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, :invalid_spdx if !Spdx.valid?(value)
  end
end
