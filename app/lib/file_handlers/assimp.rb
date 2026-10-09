class FileHandlers::Assimp < FileHandlers::Base
  # i18n-tasks-use t("file_handlers.handlers.assimp")

  ENVIRONMENTS = [:convert].freeze

  INPUT_TYPES = Mime::EXTENSION_LOOKUP.slice(
    *::Assimp.extension_list.to_s.delete("*.").split(";")
  ).values.freeze

  OUTPUT_TYPES = Mime::EXTENSION_LOOKUP.slice(
      *(0...::Assimp.aiGetExportFormatCount).map { ::Assimp.aiGetExportFormatDescription it }.map(&:file_extension)
    ).values.freeze

  def self.convert(file:, to:)
    Analysis::AssimpFileConversionJob.perform_later(file.id, to.to_sym)
  end
end
