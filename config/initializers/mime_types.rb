# Extra MIME types that Rails doesn't already know about

# 3D Models
MediaType.register "application/vnd.flock+json", :flock
MediaType.register "application/vnd.dragonfruit.voxl", :voxl
MediaType.register "application/x-3ds", :threeds, additional_types: ["image/x-3ds", "application/vnd.3ds"], additional_extensions: ["3ds"]
MediaType.register "application/x-3dsmax", :max
MediaType.register "application/x-amf", :amf
MediaType.register "application/x-ldraw", :ldr, additional_extensions: ["mpd"]
MediaType.register "application/x-openscad", :scad
MediaType.register "image/vnd.dwg", :dwg
MediaType.register "image/vnd.dxf", :dxf
MediaType.register "model/3mf", :threemf, additional_extensions: ["3mf"]
MediaType.register "model/3dm", :threedm, additional_types: ["model/vnd.3dm"], additional_extensions: ["3dm"]
MediaType.register "model/gltf", :gltf, additional_types: ["model/gltf+json", "model/gltf+binary", "model/gltf-binary"], additional_extensions: ["glb"]
MediaType.register "model/iges", :iges, additional_extensions: ["igs"]
MediaType.register "model/mtl", :mtl
MediaType.register "model/obj", :obj
MediaType.register "model/step", :step, additional_types: ["model/step+xml", "model/step+zip", "model/step-xml+zip", "application/vnd.step"], additional_extensions: ["stp", "stpnc", "p21", "210"]
MediaType.register "model/stl", :stl
MediaType.register "model/vnd.collada+xml", :collada, additional_types: ["application/vnd.dae"], additional_extensions: ["dae"]
MediaType.register "model/vnd.google.draco", :draco, additional_extensions: ["drc"]
MediaType.register "model/vrml", :vrml, additional_extensions: ["wrl"]
MediaType.register "model/x-alembic", :abc, additional_types: ["application/vnd.abc"]
MediaType.register "model/x-blender", :blend
MediaType.register "model/x-brep", :brep
MediaType.register "model/x-cheetah3d", :cheetah3d, additional_extensions: ["jas"]
MediaType.register "model/x-fbx", :fbx, additional_types: ["application/vnd.fbx"]
MediaType.register "model/x-freecad", :fcstd
MediaType.register "model/x-fusion", :f3d, additional_extensions: ["f3z"]
MediaType.register "model/x-inventor-part", :ipt
MediaType.register "model/x-inventor-assembly", :iam
MediaType.register "model/x-maya", :maya, additional_extensions: ["ma", "mb"]
MediaType.register "model/x-meshmixer", :mix
MediaType.register "model/x-modo", :modo, additional_extensions: ["lxo"]
MediaType.register "model/x-ply", :ply, additional_types: ["application/vnd.ply"]
MediaType.register "model/x-sketchup", :sketchup, additional_extensions: ["skp"]
MediaType.register "model/x-solidworks-assembly", :sldasm
MediaType.register "model/x-solidworks-part", :sldprt
MediaType.register "model/x-hfp", :hfp
MediaType.register "model/x-speedtree", :speedtree, additional_extensions: ["spm"]
MediaType.register "model/x3d", :x3d, additional_types: ["model/x3d+xml", "model/x3d-vrml", "model/x3d+fastinfoset"]

MediaType.register "application/dicom", :dcm # DICOM
MediaType.register "application/gml+xml", :gml # CityGML
MediaType.register "application/vnd.pts", :pts # Point Cloud
MediaType.register "application/vnd.vtk", :vtk # VTK Legacy
MediaType.register "application/vnd.vtp", :vtp, additional_types: ["application/vnd.vtu", "application/vnd.vti", "application/vnd.vtr", "application/vnd.vts"], additional_extensions: ["vtu", "vti", "vtr", "vts"] # VTK XML
MediaType.register "application/vnd.off", :off # Object File Format
MediaType.register "application/vnd.x", :x # DirectX
MediaType.register "application/vnd.xbf", :xbf # Open CASCADE Technology XBF format
MediaType.register "application/vnd.mdl", :mdl # QuakeMDL
MediaType.register "application/vnd.ifc", :ifc # Industry Foundation Classes
MediaType.register "application/vnd.mhd", :mha, additional_extensions: ["mhd"] # MetaHeader MetaIO
MediaType.register "application/vnd.nrrd", :nrrd, additional_extensions: ["nhdr"] # NRRD ("nearly raw raster data")
MediaType.register "application/vnd.splat", :splat # 3D Gaussian Splatting
MediaType.register "application/vnd.spz", :spz # Compressed 3D Gaussian Splatting

# Slicer formats
MediaType.register "text/x-gcode", :gcode, additional_extensions: ["bgcode"]
MediaType.register "model/x-lychee", :lychee, additional_extensions: ["lys", "lyt"]
MediaType.register "application/x-chitubox", :chitubox, additional_extensions: ["ctb", "cbddlp"]
MediaType.register "application/x-prusa-sl1", :sl1, additional_extensions: ["sl1s"]
MediaType.register "application/x-phrozen", :prz, additional_extensions: ["phz"]
MediaType.register "application/x-photon", :photon, additional_extensions: ["photons"]
MediaType.register "application/x-crealitybox", :crealitybox, additional_extensions: ["cxdlp", "cxdlpv4"]
MediaType.register "application/x-elegoo", :goo
MediaType.register "application/x-lumen", :lumen
MediaType.register "application/x-nanodlp", :nanodlp

# Images
MediaType.register "image/webp", :webp

# Archive formats
MediaType.register "application/vnd.rar", :rar
MediaType.register "application/x-7z-compressed", :sevenz, additional_extensions: ["7z"]
MediaType.register "application/x-bzip2", :bz2

# Document formats
MediaType.register "text/markdown", :md
MediaType.register "application/msword", :doc
MediaType.register "application/vnd.openxmlformats-officedocument.wordprocessingml.document", :docx
MediaType.register "application/octet-stream", :bin

# Hardware files, using types from KiCad source:
# https://gitlab.com/kicad/code/kicad/-/tree/master/resources/linux/mime
MediaType.register "application/x-gerber", :gbr, additional_types: ["application/vnd.gerber"], additional_extensions: ["gerber", "geb", "gb"]
MediaType.register "application/x-gerber-job", :gbrjob
MediaType.register "application/x-excellon", :drl
MediaType.register "application/x-kicad-project", :kicad_pro, additional_extensions: ["pro"]
MediaType.register "application/x-kicad-footprint", :kicad_mod
MediaType.register "application/x-kicad-pcb", :kicad_pcb
MediaType.register "application/x-kicad-symbol", :kicad_sym
MediaType.register "application/x-kicad-schematic", :kicad_sch, additional_extensions: ["sch"]
MediaType.register "application/x-kicad-worksheet", :kicad_wks
