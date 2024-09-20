class WritableValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, :non_writable unless value.nil? || File.writable?(value)
  end
end
