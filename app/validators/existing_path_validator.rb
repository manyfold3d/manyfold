class ExistingPathValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, "could not be found on disk" if value.nil? || !File.exist?(value)
  end
end
