class ActivityPub::ActorActivityHandler
  def self.handle_create_activity(activity_hash_or_id)
    handle_activity(activity_hash_or_id, "Create")
  end

  def self.handle_update_activity(activity_hash_or_id)
    handle_activity(activity_hash_or_id, "Update")
  end

  def self.handle_activity(activity_hash_or_id, action)
    activity = Fediverse::Request.dereference(activity_hash_or_id)

    # Get object attributes and update object
    attributes = actor_object_attributes(activity)
    return unless attributes
    object = Federails::Actor.find_or_create_by_federation_url(attributes[:federated_url]) # rubocop:disable Rails/DynamicFindBy
    object&.update!(attributes)

    if object.entity
      ActivityPub::ApplicationDeserializer.deserializer_for(object)&.update!
    else
      ActivityPub::ApplicationDeserializer.deserializer_for(object)&.create!
    end
  end

  def self.get_actor(activity)
    Federails::Actor.find_or_create_by_federation_url(
      activity["actor"].is_a?(Hash) ?
        activity.dig("actor", "id") :
        activity["actor"]
    )
  end

  # This is copied from Fediverse::Webfinger - that needs refactoring so we can use it directly

  def self.actor_object_attributes(activity)
    object = Fediverse::Request.dereference(activity["object"])

    # We only want to process actors
    return unless object["inbox"].present? && object["outbox"].present?

    id = object.delete("id")
    {
      federated_url: id,
      username: object.delete("preferredUsername"),
      name: object.delete("name"),
      server: server_and_port(id),
      inbox_url: object.delete("inbox"),
      outbox_url: object.delete("outbox"),
      followers_url: object.delete("followers"),
      followings_url: object.delete("following"),
      profile_url: object.delete("url"),
      public_key: object.delete("publicKey")&.dig("publicKeyPem"),
      extensions: object.except("@context")
    }
  end

  def self.server_and_port(string)
    uri = URI.parse string
    if uri.port && [80, 443].exclude?(uri.port)
      "#{uri.host}:#{uri.port}"
    else
      uri.host
    end
  end
end
