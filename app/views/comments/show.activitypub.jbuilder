# Comments become Notes in ActvityPub world
json.set! "@context", "https://www.w3.org/ns/activitystreams"
json.id url_for_comment(@comment)
json.type "Note"
json.content markdownify(@comment.comment)
json.context url_for([@comment.commentable, only_path: false])
