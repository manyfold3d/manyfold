# frozen_string_literal: true

class RegexArrayValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value.any? { |pattern| pattern.to_regexp.nil? }
    record.errors.add(attribute, :invalid)
  end
end
