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
      data = case oembed_data[:type]
      when "photo"
        {
          type: "Image",
          url: oembed_data[:url],
          mediaType: @object.preview_file.mime_type.to_s
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
      data.merge({
        name: @object.name,
        summary: @object.preview_file.caption
      }).compact
    end
  end
end
