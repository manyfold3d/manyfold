class FileHandlers::CrealityPrint < FileHandlers::Slic3rFamily
  # i18n-tasks-use t('model_files.download.creality_print')

  class << self
    def input_types
      # From code at https://github.com/CrealityOfficial/CrealityPrint/tree/master/src/libslic3r/Format
      Mime::EXTENSION_LOOKUP.slice("3mf", "amf", "obj", "step", "stl", "svg").values
    end

    def scheme
      "crealityprintlink"
    end
  end
end
