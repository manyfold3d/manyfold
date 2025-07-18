class CreateObjectFromUrlJob < ApplicationJob
  queue_as :low
  unique :until_executed

  def perform(url:, collection_id: nil)
    return if Link.find_by(url: url)
    # Get deserializer
    deserializer = Link.deserializer_for(url: url)
    # Create new object
    object = case deserializer&.capabilities&.dig(:class)&.name
    when "Model"
      Model.create(
        library: Library.default,
        name: url.split("://").last,
        path: SecureRandom.uuid,
        collection_id: collection_id,
        links_attributes: [{url: url}]
      )
    when "Creator"
      Creator.create(
        name: SecureRandom.uuid,
        links_attributes: [{url: url}]
      )
    when "Collection"
      Collection.create(
        name: SecureRandom.uuid,
        links_attributes: [{url: url}]
      )
    end
    object.links.first.update_metadata_from_link_later(organize: true) if object
  end
end
