module DataPackage
  class CreatorDeserializer < BaseDeserializer
    def deserialize
      return unless @object && @object["roles"]&.include?("creator")
      attributes = {name: @object["title"]}
      begin
        route_options = Rails.application.routes.recognize_path(@object["path"])
        if route_options[:controller] == "creators"
          attributes[:id] = Creator.find_param(route_options[:id]).id
        end
      rescue ActionController::RoutingError, ActiveRecord::RecordNotFound
      end
      attributes[:links_attributes] = [{url: @object["path"]}] unless attributes.has_key?(:creator_id)
      attributes
    end
  end
end
