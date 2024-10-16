# Extra MIME types that Rails doesn't already know about

# 3D Models
Mime::Type.register "model/stl", :stl
Mime::Type.register "model/obj", :obj
Mime::Type.register "model/mtl", :mtl
Mime::Type.register "model/3mf", :threemf, [], ["3mf"]
Mime::Type.register "model/x-ply", :ply
Mime::Type.register "model/x-blender", :blend
Mime::Type.register "model/x-meshmixer", :mix
Mime::Type.register "model/x-alembic", :abc
Mime::Type.register "model/step", :step, ["model/step+xml", "model/step+zip", "model/step-xml+zip"], ["stp"]
Mime::Type.register "application/x-openscad", :scad
Mime::Type.register "model/gltf", :gltf, ["model/gltf+json", "model/gltf+binary", "model/gltf-binary"], ["glb"]
Mime::Type.register "model/x-freecad", :fcstd
Mime::Type.register "model/x-brep", :brep

# Slicer formats
Mime::Type.register "text/x-gcode", :gcode
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
