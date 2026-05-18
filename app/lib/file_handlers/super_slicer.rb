class FileHandlers::SuperSlicer < FileHandlers::Slic3rFamily
  # i18n-tasks-use t('model_files.download.superslicer')

  class << self
    def input_types
      # From code at https://github.com/supermerill/SuperSlicer/tree/master_27/src/libslic3r/Format
      Mime::EXTENSION_LOOKUP.slice("3mf", "amf", "obj", "step", "stl", "svg").values
    end

    def scheme
      "prusaslicer"
    end
  end
end
