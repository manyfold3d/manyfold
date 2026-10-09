module Convertable
  extend ActiveSupport::Concern

  def convert_later(format, delay: 0.seconds)
    Analysis::FileConversionJob.set(wait: delay).perform_later(id, format.to_sym)
  end

  def convertable?(to: nil)
    converter(to: to).present?
  end

  private

  def converter(to:)
    FileHandlers.handlers_for(environment: :convert, mime_type: mime_type, output_type: to&.to_sym).first
  end
end
