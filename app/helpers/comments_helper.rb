module CommentsHelper
  def url_for_comment(comment)
    url_for([comment.commentable, comment, {only_path: false}])
  end
end
