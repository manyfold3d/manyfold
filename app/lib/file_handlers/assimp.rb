class FileHandlers::Assimp < FileHandlers::Base
  class << self
    def input_types
      Mime::EXTENSION_LOOKUP.slice(
        *::Assimp.extension_list.to_s.delete("*.").split(";")
      ).values
    end

    def output_types
      Mime::EXTENSION_LOOKUP.slice(
        *(0...::Assimp.aiGetExportFormatCount).map { |it| ::Assimp.aiGetExportFormatDescription it }.map(&:file_extension)
      ).values
    end
  end
end
