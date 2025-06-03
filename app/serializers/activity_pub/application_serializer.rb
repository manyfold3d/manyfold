module ActivityPub
  class ApplicationSerializer < BaseSerializer
    def federate?
      @object.public?
    end

    def to
      PUBLIC_COLLECTION if @object.public?
    end

    private

    def oembed_to_preview(oembed_data)
      case oembed_data[:type]
      when "photo"
        {
          type: "Image",
          url: oembed_data[:url],
          mediaType: @object.preview_file.mime_type
        }
      when "rich"
        {
          type: "Document",
          content: oembed_data[:html],
          mediaType: "text/html"
        }
      when "video"
        {
          type: "Video",
          url: oembed_data[:url],
          mediaType: @object.preview_file.mime_type.to_s
        }
      end
    end
  end
end
