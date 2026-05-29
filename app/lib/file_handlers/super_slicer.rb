class FileHandlers::SuperSlicer < FileHandlers::Slic3rFamily
  # i18n-tasks-use t('model_files.download.super_slicer')

  # From code at https://github.com/supermerill/SuperSlicer/tree/master_27/src/libslic3r/Format
  INPUT_TYPES = Mime::EXTENSION_LOOKUP.slice("3mf", "amf", "obj", "step", "stl", "svg").values.freeze

  def self.scheme
    "prusaslicer"
  end
end
