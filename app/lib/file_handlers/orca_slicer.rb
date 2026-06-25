class FileHandlers::OrcaSlicer < FileHandlers::Slic3rFamily
  # i18n-tasks-use t('model_files.download.orca_slicer')

  # From file import dialog
  INPUT_TYPES = Mime::EXTENSION_LOOKUP.slice("3mf", "abc", "amf", "obj", "ply", "step", "stl", "svg").values.freeze

  def self.scheme
    "orcaslicer"
  end

  def self.icon
    "images/external-icons/orca_slicer.png"
  end
end
