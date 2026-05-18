class FileHandlers::Cura < FileHandlers::Slic3rFamily
  # i18n-tasks-use t('model_files.download.cura')

  class << self
    def input_types
      # https://support.makerbot.com/s/article/1667411286871
      Mime::EXTENSION_LOOKUP.slice("3mf", "amf", "dae", "gcode", "gltf", "obj", "ply", "stl", "x3d").values
    end

    def scheme
      "cura"
    end
  end
end
