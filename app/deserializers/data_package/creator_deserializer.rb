module DataPackage
  class CreatorDeserializer < BaseDeserializer
    def deserialize
      return unless @object && @object["roles"]&.include?("creator")
      attributes = {
        name: @object["title"],
        caption: @object["caption"],
        notes: @object["description"],
        links_attributes: []
      }
      begin
        route_options = Rails.application.routes.recognize_path(@object["path"])
        if route_options[:controller] == "creators"
          attributes[:id] = Creator.find_param(route_options[:id]).id
        end
      rescue ActiveRecord::RecordNotFound
        # ID wasn't found, match by name instead
        attributes[:id] = Creator.find_by(name: attributes[:name])&.id
      rescue ActionController::RoutingError
        # ID wasn't found, match by name instead
        attributes[:id] = Creator.find_by(name: attributes[:name])&.id
        attributes[:links_attributes] << {url: @object["path"]} if @object["path"]&.match?(URI::RFC2396_PARSER.make_regexp)
      end
      attributes[:links_attributes].concat(@object["links"]&.map { LinkDeserializer.new(it).deserialize } || [])
      attributes.compact_blank
    end
  end
end
