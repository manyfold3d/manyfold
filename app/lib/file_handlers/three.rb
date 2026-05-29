class FileHandlers::Three < FileHandlers::Base
  ENVIRONMENTS = [:browser, :preview_frame].freeze
  INPUT_TYPES = Mime::EXTENSION_LOOKUP.slice(
    "stl", "obj", "3mf", "ply", "gltf", "glb", "drc", "fbx", "3ds", "gcode", "mpd", "ldr", "3dm"
  ).values.freeze

  def self.component
    Components::Renderers::Three
  end
end
