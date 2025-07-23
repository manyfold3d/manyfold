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

    def author_properties(creator)
      return {} if creator.nil?
      {
        author_name: creator.name,
        author_url: Rails.application.routes.url_helpers.creator_url(creator)
      }
    end

    def model_file_properties(model_file)
      props = if model_file&.is_image?
        photo_properties(model_file)
      elsif model_file&.is_renderable?
        renderable_properties(model_file)
      elsif model_file&.is_video?
        video_properties(model_file)
      else
        link_properties
      end
      props.merge({
        name: model_file&.name,
        summary: model_file&.caption
      }).compact
    end

    def link_properties
      {
        type: "link"
      }
    end

    def photo_properties(model_file)
      width = @maxwidth || 512 # TODO proper scale calc based on image size
      height = @maxheight || 512
      {
        type: "photo",
        url: Rails.application.routes.url_helpers.model_model_file_url(model_file.model, model_file, format: model_file.extension),
        width: width,
        height: height,
        mediaType: model_file.mime_type.to_s
      }
    end

    def video_properties(model_file)
      width = @maxwidth || 512
      height = [@maxheight, width * 0.75].compact.min # TODO proper aspect ratio calculation
      html = <<~EOF
        <video controls width="#{width}" height="#{height}">
          <source
            src="#{Rails.application.routes.url_helpers.model_model_file_url(model_file.model, model_file, format: model_file.extension)}"
            type="#{model_file.mime_type}"
          />
        </video>
      EOF
      {
        type: "video",
        url: Rails.application.routes.url_helpers.model_model_file_url(model_file.model, model_file, format: model_file.extension),
        html: html,
        width: width,
        height: height,
        mediaType: model_file.mime_type.to_s
      }
    end

    def renderable_properties(model_file)
      width = @maxwidth || 512
      height = @maxheight || 512
      html = <<~EOF
        <iframe
          src="#{Rails.application.routes.url_helpers.model_model_file_url(model_file.model, model_file, embed: true)}"
          width="#{width}" height="#{height}" loading="lazy" referrerpolicy="no-referrer" scrolling="no"
          style="overflow:hidden; border: none" sandbox="allow-scripts allow-pointer-lock allow-same-origin">
        </iframe>
      EOF
      {
        type: "rich",
        html: html,
        width: width,
        height: height,
        mediaType: model_file.mime_type.to_s
      }
    end
  end
end
