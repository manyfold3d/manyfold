class FileHandlers::ElegooSlicer < FileHandlers::Slic3rFamily
  # i18n-tasks-use t('model_files.download.elegoo_slicer')

  INPUT_TYPES = Mime::EXTENSION_LOOKUP.slice("3mf", "amf", "obj", "step", "stl", "svg").values.freeze

  def self.scheme
    "elegooslicer"
  end

  def self.icon
    "images/external-icons/elegoo_slicer.png"
  end
end
