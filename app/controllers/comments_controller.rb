class CommentsController < ApplicationController
  before_action :get_commentable
  before_action :get_comment, except: [:create]

  def show
    respond_to do |format|
      format.activitypub
      format.html { redirect_to @commentable, status: :see_other }
    end
  end

  def create
    @comment = @commentable.comments.new(comment_params.merge(commenter: current_user))
    authorize @comment
    respond_to do |format|
      format.html do
        if @commentable.save
          redirect_to @commentable, status: :see_other
        else
          render :nothing, status: :unprocessable_content
        end
      end
    end
  end

  def destroy
    authorize @comment
    respond_to do |format|
      format.html do
        if @comment.destroy!
          redirect_to @commentable, status: :see_other, notice: t(".destroyed")
        else
          render :nothing, status: :unprocessable_content
        end
      end
    end
  end

  private

  def comment_params
    params.expect(comment: [:comment])
  end

  def get_comment
    @comment = policy_scope(@commentable.comments).find_param(params[:id])
  end

  def get_commentable
    # Allowlist for commentable class param.
    # This isn't actually supplied by the user, it comes from the router, but best to be double safe.
    commentables = {
      "Model" => Model,
      "Creator" => Creator,
      "Collection" => Collection
    }
    commentable = commentables[params[:commentable_class]]
    raise ActionController::BadRequest if commentable.nil?
    # Get the actual item
    commentable_param = params[:commentable_class].parameterize + "_id"
    id = params[commentable_param]
    @commentable = policy_scope(commentable).find_param(id)
    authorize @commentable, :show?
  end
end
