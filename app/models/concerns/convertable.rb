module Convertable
  extend ActiveSupport::Concern

  def scene
    Shrine.with_file(attachment.open) do
      scene = Assimp.import_file(it.path)
      scene.apply_post_processing(Assimp::PostProcessSteps[
        :JoinIdenticalVertices,
        :Triangulate
      ])
    end
  end

  def convert_later(format, delay: 0.seconds)
    Analysis::FileConversionJob.set(wait: delay).perform_later(id, format.to_sym)
  end

  def convertable?(to: nil)
    return false unless FileHandlers::Assimp.can_load? mime_type
    to.nil? || FileHandlers::Assimp.can_save?(to)
  end
end
