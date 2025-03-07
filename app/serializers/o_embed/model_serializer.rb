module OEmbed
  class ModelSerializer < ApplicationSerializer
    def serialize
      {
        title: @object.name
      }.merge(generic_properties, author_properties, type_properties)
    end

    private

    def author_properties
      return {} if @object.creator.nil?
      {
        author_name: @object.creator.name,
        author_url: Rails.application.routes.url_helpers.creator_url(@object.creator)
      }
    end

    def type_properties
      if @object.preview_file&.is_image?
        photo_properties
      elsif @object.preview_file&.is_renderable?
        renderable_properties
      elsif @object.preview_file&.is_video?
        video_properties
      else
        link_properties
      end
    end

    def link_properties
      {
        type: "link"
      }
    end

    def photo_properties
      width = @maxwidth || 512 # TODO proper scale calc based on image size
      height = @maxheight || 512
      {
        type: "photo",
        url: Rails.application.routes.url_helpers.model_model_file_url(@object, @object.preview_file, format: @object.preview_file.extension),
        width: width,
        height: height
      }
    end

    def video_properties
      width = @maxwidth || 512
      height = [@maxheight, width * 0.75].compact.min # TODO proper aspect ratio calculation
      html = <<~EOF
        <video controls width="#{width}" height="#{height}">
          <source
            src="#{Rails.application.routes.url_helpers.model_model_file_url(@object, @object.preview_file, format: @object.preview_file.extension)}"
            type="#{@object.preview_file.mime_type}"
          />
        </video>
      EOF
      {
        type: "video",
        html: html,
        width: width,
        height: height
      }
    end

    def renderable_properties
      width = @maxwidth || 512
      height = @maxheight || 512
      html = <<~EOF
        <iframe
          src="#{Rails.application.routes.url_helpers.model_model_file_url(@object, @object.preview_file, embed: true)}"
          width="#{width}" height="#{height}" loading="lazy" referrerpolicy="no-referrer" scrolling="no" style="overflow:hidden"
          sandbox="allow-scripts allow-pointer-lock allow-same-origin"
        </iframe>
      EOF
      {
        type: "rich",
        html: html,
        width: width,
        height: height
      }
    end
  end
end
