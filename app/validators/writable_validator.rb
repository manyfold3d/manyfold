class WritableValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, :non_writable unless value.nil? || FileTest.writable?(value)
  end
end
