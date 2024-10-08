# Comments become Notes in ActvityPub world
json.set! "@context", "https://www.w3.org/ns/activitystreams"
json.id @comment.federated_url
json.type "Note"
json.content markdownify(@comment.comment)
json.context url_for([@comment.commentable, only_path: false])
