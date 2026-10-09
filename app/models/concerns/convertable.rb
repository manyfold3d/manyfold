module Convertable
  extend ActiveSupport::Concern

  def convert_later(format, delay: 0.seconds)
    Analysis::FileConversionJob.set(wait: delay).perform_later(id, format.to_sym)
  end

  def convertable?(to: nil)
    return false unless FileHandlers::Assimp.can_load? mime_type
    to.nil? || FileHandlers::Assimp.can_save?(to)
  end
end
