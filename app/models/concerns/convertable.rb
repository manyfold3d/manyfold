module Convertable
  extend ActiveSupport::Concern

  def convert_later(format)
    converter(to: format)&.convert(file: self, to: format)
  end

  def convertable?(to: nil)
    converter(to: to).present?
  end

  private

  def converter(to:)
    FileHandlers.handlers_for(environment: :convert, mime_type: mime_type, output_type: to&.to_sym).first
  end
end
