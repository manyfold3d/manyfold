class FileHandlers::F3dWasm < FileHandlers::Base
  ENVIRONMENTS = [:browser, :preview_frame].freeze
  INPUT_TYPES = Mime::EXTENSION_LOOKUP.slice(*%w[gml gltf glb obj ply pts stl vtk vtp vtu vtkhdf 3ds wrl vrml fbx dae dxf off x 3mf ex2 exo e g stp step igs iges brep xbf drc mdl nc cdf ncdf ifc]).values.uniq.freeze

  def self.priority
    100
  end

  def self.component
    Components::Renderers::F3d
  end
end
