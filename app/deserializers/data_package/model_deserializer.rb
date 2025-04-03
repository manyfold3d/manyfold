module DataPackage
  class ModelDeserializer < BaseDeserializer
    def deserialize
      {
        name: @object["title"],
        caption: @object["description"].split("\n\n", 2).first,
        notes: @object["description"].split("\n\n", 2).last,
        links_attributes: [{url: @object["homepage"]}],
        preview_file: @object["image"],
        tag_list: @object["keywords"],
        license: @object.dig("licenses", 0, "name"),
        model_files: @object["resources"]&.map { |it| ModelFileDeserializer.new(it).deserialize },
        creator: CreatorDeserializer.new(@object["contributors"]&.find { |it| it["roles"].include?("creator") }).deserialize
      }.compact
    end
  end
end
