# Configuration options for our API endpoints

# oEmbed
Mime::Type.register "application/json+oembed", :oembed

# JSON-LD
Mime::Type.register "application/ld+json", :json_ld
