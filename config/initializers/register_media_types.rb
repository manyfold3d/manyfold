# Categorise built-in types

MediaType.categorize(:html, :document)
MediaType.categorize(:text, :document)
MediaType.categorize(:js, :document)
MediaType.categorize(:pdf, :document)

MediaType.categorize(:png, :image)
MediaType.categorize(:jpeg, :image)
MediaType.categorize(:gif, :image)
MediaType.categorize(:bmp, :image)
MediaType.categorize(:tiff, :image)
MediaType.categorize(:svg, :image)
MediaType.categorize(:webp, :image)

MediaType.categorize(:mpeg, :video)
MediaType.categorize(:webm, :video)
MediaType.categorize(:mp4, :video)

MediaType.categorize(:zip, :archive)
MediaType.categorize(:gzip, :archive)

# Add extra MIME types that Rails doesn't already know about

# 3D Models
MediaType.register "application/vnd.flock+json", :flock, category: :model
MediaType.register "application/vnd.dragonfruit.voxl", :voxl, category: :model
MediaType.register "application/x-3ds", :threeds, additional_types: ["image/x-3ds", "application/vnd.3ds"], additional_extensions: ["3ds"], category: :model
MediaType.register "application/x-3dsmax", :max, category: :model
MediaType.register "application/x-amf", :amf, category: :model
MediaType.register "application/x-ldraw", :ldr, additional_extensions: ["mpd"], category: :model
MediaType.register "application/x-openscad", :scad, category: :model
MediaType.register "image/vnd.dwg", :dwg, category: :model
MediaType.register "image/vnd.dxf", :dxf, category: :model
MediaType.register "model/3mf", :threemf, additional_extensions: ["3mf"], category: :model
MediaType.register "model/3dm", :threedm, additional_types: ["model/vnd.3dm"], additional_extensions: ["3dm"], category: :model
MediaType.register "model/gltf", :gltf, additional_types: ["model/gltf+json", "model/gltf+binary", "model/gltf-binary"], additional_extensions: ["glb"], category: :model
MediaType.register "model/iges", :iges, additional_extensions: ["igs"], category: :model
MediaType.register "model/mtl", :mtl, category: :model
MediaType.register "model/obj", :obj, category: :model
MediaType.register "model/step", :step, additional_types: ["model/step+xml", "model/step+zip", "model/step-xml+zip", "application/vnd.step"], additional_extensions: ["stp", "stpnc", "p21", "210"], category: :model
MediaType.register "model/stl", :stl, category: :model
MediaType.register "model/vnd.collada+xml", :collada, additional_types: ["application/vnd.dae"], additional_extensions: ["dae"], category: :model
MediaType.register "model/vnd.google.draco", :draco, additional_extensions: ["drc"], category: :model
MediaType.register "model/vrml", :vrml, additional_extensions: ["wrl"], category: :model
MediaType.register "model/x-alembic", :abc, additional_types: ["application/vnd.abc"], category: :model
MediaType.register "model/x-blender", :blend, category: :model
MediaType.register "model/x-brep", :brep, category: :model
MediaType.register "model/x-cheetah3d", :cheetah3d, additional_extensions: ["jas"], category: :model
MediaType.register "model/x-fbx", :fbx, additional_types: ["application/vnd.fbx"], category: :model
MediaType.register "model/x-freecad", :fcstd, category: :model
MediaType.register "model/x-fusion", :f3d, additional_extensions: ["f3z"], category: :model
MediaType.register "model/x-inventor-part", :ipt, category: :model
MediaType.register "model/x-inventor-assembly", :iam, category: :model
MediaType.register "model/x-maya", :maya, additional_extensions: ["ma", "mb"], category: :model
MediaType.register "model/x-meshmixer", :mix, category: :model
MediaType.register "model/x-modo", :modo, additional_extensions: ["lxo"], category: :model
MediaType.register "model/x-ply", :ply, additional_types: ["application/vnd.ply"], category: :model
MediaType.register "model/x-sketchup", :sketchup, additional_extensions: ["skp"], category: :model
MediaType.register "model/x-solidworks-assembly", :sldasm, category: :model
MediaType.register "model/x-solidworks-part", :sldprt, category: :model
MediaType.register "model/x-hfp", :hfp, category: :model
MediaType.register "model/x-speedtree", :speedtree, additional_extensions: ["spm"], category: :model
MediaType.register "model/x3d", :x3d, additional_types: ["model/x3d+xml", "model/x3d-vrml", "model/x3d+fastinfoset"], category: :model

MediaType.register "application/dicom", :dcm, category: :model # DICOM
MediaType.register "application/gml+xml", :gml, category: :model # CityGML
MediaType.register "application/vnd.pts", :pts, category: :model # Point Cloud
MediaType.register "application/vnd.vtk", :vtk, category: :model # VTK Legacy
MediaType.register "application/vnd.vtp", :vtp, additional_types: ["application/vnd.vtu", "application/vnd.vti", "application/vnd.vtr", "application/vnd.vts"], additional_extensions: ["vtu", "vti", "vtr", "vts"], category: :model # VTK XML
MediaType.register "application/vnd.off", :off, category: :model # Object File Format
MediaType.register "application/vnd.x", :x, category: :model # DirectX
MediaType.register "application/vnd.xbf", :xbf, category: :model # Open CASCADE Technology XBF format
MediaType.register "application/vnd.mdl", :mdl, category: :model # QuakeMDL
MediaType.register "application/vnd.ifc", :ifc, category: :model # Industry Foundation Classes
MediaType.register "application/vnd.mhd", :mha, additional_extensions: ["mhd"], category: :model # MetaHeader MetaIO
MediaType.register "application/vnd.nrrd", :nrrd, additional_extensions: ["nhdr"], category: :model # NRRD ("nearly raw raster data")
MediaType.register "application/vnd.splat", :splat, category: :model # 3D Gaussian Splatting
MediaType.register "application/vnd.spz", :spz, category: :model # Compressed 3D Gaussian Splatting

# Slicer formats
MediaType.register "text/x-gcode", :gcode, additional_extensions: ["bgcode"], category: :model
MediaType.register "model/x-lychee", :lychee, additional_extensions: ["lys", "lyt"], category: :model
MediaType.register "application/x-chitubox", :chitubox, additional_extensions: ["ctb", "cbddlp"], category: :slicer
MediaType.register "application/x-prusa-sl1", :sl1, additional_extensions: ["sl1s"], category: :slicer
MediaType.register "application/x-phrozen", :prz, additional_extensions: ["phz"], category: :slicer
MediaType.register "application/x-photon", :photon, additional_extensions: ["photons"], category: :slicer
MediaType.register "application/x-crealitybox", :crealitybox, additional_extensions: ["cxdlp", "cxdlpv4"], category: :slicer
MediaType.register "application/x-elegoo", :goo, category: :slicer
MediaType.register "application/x-lumen", :lumen, category: :slicer
MediaType.register "application/x-nanodlp", :nanodlp, category: :slicer

# Images
MediaType.register "image/webp", :webp, category: :image

# Archive formats
MediaType.register "application/vnd.rar", :rar, category: :archive
MediaType.register "application/x-7z-compressed", :sevenz, additional_extensions: ["7z"], category: :archive
MediaType.register "application/x-bzip2", :bz2, category: :archive

# Document formats
MediaType.register "text/markdown", :md, category: :document
MediaType.register "application/msword", :doc, category: :document
MediaType.register "application/vnd.openxmlformats-officedocument.wordprocessingml.document", :docx, category: :document
MediaType.register "application/octet-stream", :bin, category: :document

# Hardware files, using types from KiCad source:
# https://gitlab.com/kicad/code/kicad/-/tree/master/resources/linux/mime
MediaType.register "application/x-gerber", :gbr, additional_types: ["application/vnd.gerber"], additional_extensions: ["gerber", "geb", "gb"], category: :document
MediaType.register "application/x-gerber-job", :gbrjob, category: :document
MediaType.register "application/x-excellon", :drl, category: :document
MediaType.register "application/x-kicad-project", :kicad_pro, additional_extensions: ["pro"], category: :document
MediaType.register "application/x-kicad-footprint", :kicad_mod, category: :document
MediaType.register "application/x-kicad-pcb", :kicad_pcb, category: :document
MediaType.register "application/x-kicad-symbol", :kicad_sym, category: :document
MediaType.register "application/x-kicad-schematic", :kicad_sch, additional_extensions: ["sch"], category: :document
MediaType.register "application/x-kicad-worksheet", :kicad_wks, category: :document
