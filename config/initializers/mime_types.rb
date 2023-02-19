# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

Mime::Type.register "model/stl", :stl
Mime::Type.register "model/obj", :obj
Mime::Type.register "model/3mf", :threemf, [], ["3mf"]
Mime::Type.register "model/x-ply", :ply
Mime::Type.register "model/x-blender", :blend
Mime::Type.register "model/x-meshmixer", :mix
Mime::Type.register "model/x-alembic", :abc
Mime::Type.register "model/step", :step, [], ["stp"]
Mime::Type.register "model/x-lychee", :lychee, [], ["lys", "lyt"]
Mime::Type.register "model/x-chitubox", :chitubox, [], ["ctb"]
Mime::Type.register "image/webp", :webp
