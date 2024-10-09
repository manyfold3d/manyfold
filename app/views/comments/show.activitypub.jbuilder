json.set! "@context", "https://www.w3.org/ns/activitystreams"
json.merge! @comment.to_activitypub_object
