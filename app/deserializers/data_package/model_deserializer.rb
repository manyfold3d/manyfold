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
        model_files: @object["resources"]&.map { ModelFileDeserializer.new(it).deserialize },
        creator: CreatorDeserializer.new(@object["contributors"]&.find { it["roles"].include?("creator") }).deserialize,
        collections: (@object["collections"] || []).map { CollectionDeserializer.new(it).deserialize },
        entrypoint: @object.dig("entrypoint", "path"),
        entrypoint_fragment: @object.dig("entrypoint", "fragment")
      }.compact
    end

    private

    def parse_links
      links = (@object["links"] || []).map { LinkDeserializer.new(it).deserialize }
      links << {url: @object["homepage"]} if @object["homepage"]
      links
    end
  end
end
