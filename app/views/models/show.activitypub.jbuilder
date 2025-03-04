json.set! "@context", "https://www.w3.org/ns/activitystreams"
json.merge! @model.to_activitypub_object
