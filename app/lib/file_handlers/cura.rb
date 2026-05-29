class FileHandlers::Cura < FileHandlers::Slic3rFamily
  # i18n-tasks-use t('model_files.download.cura')

  INPUT_TYPES = Mime::EXTENSION_LOOKUP.slice("3mf", "amf", "dae", "gcode", "gltf", "obj", "ply", "stl", "x3d").values.freeze

  def self.scheme
    "cura"
  end
end
