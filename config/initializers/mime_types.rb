# Extra MIME types that Rails doesn't already know about

# 3D Models
Mime::Type.register "application/vnd.flock+json", :flock
Mime::Type.register "application/x-3ds", :threeds, ["image/x-3ds", "application/vnd.3ds"], ["3ds"]
Mime::Type.register "application/x-3dsmax", :max
Mime::Type.register "application/x-amf", :amf
Mime::Type.register "application/x-ldraw", :ldr, [], ["mpd"]
Mime::Type.register "application/x-openscad", :scad
Mime::Type.register "image/vnd.dwg", :dwg
Mime::Type.register "image/vnd.dxf", :dxf
Mime::Type.register "model/3mf", :threemf, [], ["3mf"]
Mime::Type.register "model/3dm", :threedm, ["model/vnd.3dm"], ["3dm"]
Mime::Type.register "model/gltf", :gltf, ["model/gltf+json", "model/gltf+binary", "model/gltf-binary"], ["glb"]
Mime::Type.register "model/iges", :iges, [], ["igs"]
Mime::Type.register "model/mtl", :mtl
Mime::Type.register "model/obj", :obj
Mime::Type.register "model/step", :step, ["model/step+xml", "model/step+zip", "model/step-xml+zip", "application/vnd.step"], ["stp", "stpnc", "p21", "210"]
Mime::Type.register "model/stl", :stl
Mime::Type.register "model/vnd.collada+xml", :collada, ["application/vnd.dae"], ["dae"]
Mime::Type.register "model/vnd.google.draco", :draco, [], ["drc"]
Mime::Type.register "model/vrml", :vrml, [], ["wrl"]
Mime::Type.register "model/x-alembic", :abc, ["application/vnd.abc"]
Mime::Type.register "model/x-blender", :blend
Mime::Type.register "model/x-brep", :brep
Mime::Type.register "model/x-cheetah3d", :cheetah3d, [], ["jas"]
Mime::Type.register "model/x-fbx", :fbx, ["application/vnd.fbx"]
Mime::Type.register "model/x-freecad", :fcstd
Mime::Type.register "model/x-fusion", :f3d, [], ["f3z"]
Mime::Type.register "model/x-inventor-part", :ipt
Mime::Type.register "model/x-inventor-assembly", :iam
Mime::Type.register "model/x-maya", :maya, [], ["ma", "mb"]
Mime::Type.register "model/x-meshmixer", :mix
Mime::Type.register "model/x-modo", :modo, [], ["lxo"]
Mime::Type.register "model/x-ply", :ply, ["application/vnd.ply"]
Mime::Type.register "model/x-sketchup", :sketchup, [], ["skp"]
Mime::Type.register "model/x-solidworks-assembly", :sldasm
Mime::Type.register "model/x-solidworks-part", :sldprt
Mime::Type.register "model/x-hfp", :hfp
Mime::Type.register "model/x-speedtree", :speedtree, [], ["spm"]
Mime::Type.register "model/x3d", :x3d, ["model/x3d+xml", "model/x3d-vrml", "model/x3d+fastinfoset"]

# Slicer formats
Mime::Type.register "text/x-gcode", :gcode, [], ["bgcode"]
Mime::Type.register "model/x-lychee", :lychee, [], ["lys", "lyt"]
Mime::Type.register "model/x-chitubox", :chitubox, [], ["ctb"]

# Images
Mime::Type.register "image/webp", :webp

# Archive formats
Mime::Type.register "application/vnd.rar", :rar
Mime::Type.register "application/x-7z-compressed", :sevenz, [], ["7z"]
Mime::Type.register "application/x-bzip2", :bz2

# Document formats
Mime::Type.register "text/markdown", :md
Mime::Type.register "application/msword", :doc
Mime::Type.register "application/vnd.openxmlformats-officedocument.wordprocessingml.document", :docx
Mime::Type.register "application/octet-stream", :bin

# Hardware files, using types from KiCad source:
# https://gitlab.com/kicad/code/kicad/-/tree/master/resources/linux/mime
Mime::Type.register "application/x-gerber", :gbr, ["application/vnd.gerber"], ["gerber", "geb", "gb"]
Mime::Type.register "application/x-gerber-job", :gbrjob
Mime::Type.register "application/x-excellon", :drl
Mime::Type.register "application/x-kicad-project", :kicad_pro, [], ["pro"]
Mime::Type.register "application/x-kicad-footprint", :kicad_mod
Mime::Type.register "application/x-kicad-pcb", :kicad_pcb
Mime::Type.register "application/x-kicad-symbol", :kicad_sym
Mime::Type.register "application/x-kicad-schematic", :kicad_sch, [], ["sch"]
Mime::Type.register "application/x-kicad-worksheet", :kicad_wks
