json.set! "@context", [
  "https://www.w3.org/ns/activitystreams",
  {
    QuoteAuthorization: "https://w3id.org/fep/044f#QuoteAuthorization",
    gts: "https://gotosocial.org/ns#",
    interactingObject: {
      "@id": "gts:interactingObject",
      "@type": "@id"
    },
    interactionTarget: {
      "@id": "gts:interactionTarget",
      "@type": "@id"
    }
  }
]
json.type "QuoteAuthorization"
json.id Rails.application.routes.url_helpers.federails_server_quote_authorization_url(@quote_authorization)
json.attributedTo @quote_authorization.federails_actor.federated_url
json.interactingObject @quote_authorization.interacting_object_url
json.interactionTarget @quote_authorization.interaction_target.federated_url
