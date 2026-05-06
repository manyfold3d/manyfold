class FileHandlers::Three < FileHandlers::Base
  class << self
    def scopes
      [:browser]
    end

    def input_types
      Mime::EXTENSION_LOOKUP.slice(
        "stl", "obj", "3mf", "ply", "gltf", "glb", "drc", "fbx", "3ds", "gcode", "mpd", "ldr", "3dm"
      ).values
    end
  end
end
