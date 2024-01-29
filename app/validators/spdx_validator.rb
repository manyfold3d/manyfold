class SpdxValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, "is not a valid license" if !Spdx.valid?(value)
  end
end
