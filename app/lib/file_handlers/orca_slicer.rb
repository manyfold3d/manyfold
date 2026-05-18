class FileHandlers::OrcaSlicer < FileHandlers::Slic3rFamily
  # i18n-tasks-use t('model_files.download.orca_slicer')

  class << self
    def input_types
      # From file import dialog
      Mime::EXTENSION_LOOKUP.slice("3mf", "abc", "amf", "obj", "ply", "step", "stl", "svg").values
    end

    def scheme
      "orcaslicer"
    end
  end
end
