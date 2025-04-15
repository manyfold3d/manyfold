# Configuration options for our API endpoints

# oEmbed
Mime::Type.register "application/json+oembed", :oembed

# API format
Mime::Type.register "application/vnd.manyfold.v0+json", :manyfold_api_v0
