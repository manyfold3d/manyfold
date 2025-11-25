module ManyfoldApi::V0
  class CreatorDeserializer < BaseDeserializer
    def deserialize
      return unless @object
      {
        name: @object["name"],
        slug: @object["slug"],
        caption: @object["caption"],
        notes: @object["description"],
        links_attributes: @object["links"]&.map { |it| LinkDeserializer.new(object: it, user: @user).deserialize }
      }.compact
    end

    def self.schema
      {
        type: :object,
        properties: {
          name: {type: :string, example: "Bruce Wayne"},
          slug: {type: :string, example: "bruce-wayne"},
          caption: {type: :string, example: "A short description"},
          description: {type: :string, example: "Lorem ipsum dolor sit amet..."}, # rubocop:disable I18n/RailsI18n/DecorateString
          links: {
            type: :array,
            items: LinkDeserializer.schema_ref
          }
        },
        required: ["name"]
      }
    end
  end
end
