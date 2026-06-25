class FileHandlers::CrealityPrint < FileHandlers::Slic3rFamily
  # i18n-tasks-use t('model_files.download.creality_print')

  # From code at https://github.com/CrealityOfficial/CrealityPrint/tree/master/src/libslic3r/Format
  INPUT_TYPES = Mime::EXTENSION_LOOKUP.slice("3mf", "amf", "obj", "step", "stl", "svg").values.freeze

  def self.scheme
    "crealityprintlink"
  end

  def self.icon
    "images/external-icons/creality_print.png"
  end
end
