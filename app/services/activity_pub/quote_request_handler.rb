class ActivityPub::QuoteRequestHandler
  def self.handle_quote_request(activity_hash_or_id)
    real_activity = Fediverse::Request.dereference(activity_hash_or_id)

    quoting_actor = Federails::Actor.find_or_create_by_object real_activity["actor"]

    local_object_route = Federails::Utils::Host.local_route(
      Fediverse::Request.dereference(real_activity["object"])["id"]
    )

    object = case local_object_route[:publishable_type]
    when "comments"
      Comment.find_param(local_object_route[:id])
    end

    quote = Fediverse::Request.dereference(real_activity["instrument"])

    quote_authorization = Federails::QuoteAuthorization.create!(
      quote_request_url: real_activity["id"],
      quoting_actor: quoting_actor,
      interaction_target: object,
      interacting_object_url: quote["id"],
      federails_actor: object.federails_actor
    )

    object&.on_new_quote_request(quote_authorization)
  end
end
