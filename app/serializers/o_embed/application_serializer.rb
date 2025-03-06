module OEmbed
  class ApplicationSerializer
    def initialize(object)
      @object = object
    end

    def basic_properties
      {
        version: "1.0",
        provider_name: ENV.fetch("SITE_NAME", "Manyfold"),
        provider_url: Rails.application.routes.url_helpers.root_url
      }
    end
  end
end
