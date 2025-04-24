module DataPackage
  class ModelDeserializer < BaseDeserializer
    def deserialize
      {
        name: @object["title"],
        caption: @object["caption"],
        notes: @object["description"],
        links_attributes: parse_links,
        preview_file: @object["image"],
        tag_list: @object["keywords"],
        sensitive: @object["sensitive"],
        license: @object.dig("licenses", 0, "name"),
        model_files: @object["resources"]&.map { |it| ModelFileDeserializer.new(it).deserialize },
        creator: CreatorDeserializer.new(@object["contributors"]&.find { |it| it["roles"].include?("creator") }).deserialize,
        collection: CollectionDeserializer.new(@object.dig("collections", 0)).deserialize
      }.compact
    end

    private

    def parse_links
      links = (@object["links"] || []).map { |it| LinkDeserializer.new(it).deserialize }
      links << {url: @object["homepage"]} if @object["homepage"]
      links.reject { |it| it[:url] == self_link }
    end

    def self_link
      Rails.application.routes.url_helpers.model_url(id: @object["name"])
    rescue ActionController::UrlGenerationError
    end
  end
end
