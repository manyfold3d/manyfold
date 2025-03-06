module OEmbed
  class ApplicationSerializer
    def initialize(object, maxwidth: nil, maxheight: nil)
      @object = object
      @maxwidth = maxwidth
      @maxheight = maxheight
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
