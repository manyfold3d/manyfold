class ExistingPathValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, :not_found if value.nil? || !File.exist?(value)
  end
end
