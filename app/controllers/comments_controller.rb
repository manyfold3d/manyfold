class CommentsController < ApplicationController
  before_action :get_commentable
  before_action :get_comment

  def show
    respond_to do |format|
      format.activitypub { render json: @comment.to_activitypub_object(include_context: true) }
    end
  end

  private

  def get_comment
    @comment = @commentable.comments.find_param(params[:id])
  end

  def get_commentable
    commentable = params[:commentable_class].constantize
    commentable_param = params[:commentable_class].parameterize + "_id"
    id = params[commentable_param]
    @commentable = policy_scope(commentable).find_param(id)
    authorize @commentable
  end
end
