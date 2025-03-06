module OEmbed
  class ApplicationSerializer
    def initialize(object, options = {})
      @object = object
      @maxwidth = options[:maxwidth]
      @maxheight = options[:maxheight]
    end

    def generic_properties
      {
        version: "1.0",
        provider_name: ENV.fetch("SITE_NAME", "Manyfold"),
        provider_url: Rails.application.routes.url_helpers.root_url,
        cache_age: 86400
      }
    end
  end
end
