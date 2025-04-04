module DataPackage
  class CollectionDeserializer < BaseDeserializer
    def deserialize
      return unless @object
      attributes = {
        name: @object["title"],
        caption: @object["caption"],
        notes: @object["description"]
      }
      begin
        route_options = Rails.application.routes.recognize_path(@object["path"])
        if route_options[:controller] == "collections"
          attributes[:id] = Collection.find_param(route_options[:id]).id
        end
      rescue ActionController::RoutingError, ActiveRecord::RecordNotFound
      end
      attributes[:links_attributes] = @object["links"]&.map { |it| LinkDeserializer.new(it).deserialize } || []
      attributes[:links_attributes] << {url: @object["path"]} unless attributes.has_key?(:id)
      attributes.compact
    end
  end
end
