class FileHandlers::ElegooSlicer < FileHandlers::Slic3rFamily
  # i18n-tasks-use t('model_files.download.elegoo_slicer')

  class << self
    def input_types
      # From code at https://github.com/ELEGOO-3D/ElegooSlicer/tree/main/src/libslic3r/Format
      Mime::EXTENSION_LOOKUP.slice("3mf", "amf", "obj", "step", "stl", "svg").values
    end

    def scheme
      "elegooslicer"
    end
  end
end
