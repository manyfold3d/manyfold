class FileHandlers::Assimp < FileHandlers::Base
  ENVIRONMENTS = [:server].freeze

  INPUT_TYPES = Mime::EXTENSION_LOOKUP.slice(
    *::Assimp.extension_list.to_s.delete("*.").split(";")
  ).values.freeze

  OUTPUT_TYPES = Mime::EXTENSION_LOOKUP.slice(
      *(0...::Assimp.aiGetExportFormatCount).map { |it| ::Assimp.aiGetExportFormatDescription it }.map(&:file_extension)
    ).values.freeze
end
