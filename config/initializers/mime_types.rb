# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

Mime::Type.register "model/stl", :stl
Mime::Type.register "model/obj", :obj
Mime::Type.register "application/vnd.ms-package.3dmanufacturing-3dmodel+xml", :threemf, [], ["3mf"]
Mime::Type.register "text/plain", :ply
Mime::Type.register "application/octet-stream", :blend
Mime::Type.register "application/octet-stream", :mix
