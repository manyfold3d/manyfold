class CreateObjectFromUrlJob < ApplicationJob
  queue_as :low
  unique :until_executed

  def perform(url:, collection_id: nil, owner: nil)
    return if Link.find_by(url: url)
    # Get deserializer
    deserializer = Link.deserializer_for(url: url)
    # Set up create options common to all
    common_options = {
      name: "Importing from #{url.split("://").last} ...",
      links_attributes: [{url: url}],
      caber_relations_attributes: (owner ? [{permission: "own", subject: owner}] : [])
    }
    # Create new object
    object = case deserializer&.capabilities&.dig(:class)&.name
    when "Model"
      Model.create(common_options.merge({
        library: Library.default,
        path: SecureRandom.uuid,
        collection_id: collection_id
      }))
    when "Creator"
      Creator.create(common_options)
    when "Collection"
      Collection.create(common_options)
    end
    object.links.first.update_metadata_from_link_later(organize: true) if object
  end
end
