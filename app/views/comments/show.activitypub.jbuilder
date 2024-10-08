# Comments become Notes in ActvityPub world
json.set! "@context", "https://www.w3.org/ns/activitystreams"
json.id @comment.federated_url
json.type "Note"
json.content markdownify(@comment.comment)
json.context url_for([@comment.commentable, only_path: false])
json.published @comment.created_at&.iso8601
if @comment.commenter&.actor&.respond_to? :federated_url
  json.attributedTo @comment.commenter.actor.federated_url
end
json.to ["https://www.w3.org/ns/activitystreams#Public"]
json.cc [@comment.commenter.actor.followers_url]
