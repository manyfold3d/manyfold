class CollectionsController < ApplicationController
  def index
    @collections = ActsAsTaggableOn::Tag.for_context(:collections)
  end

  def show
    @collection = ActsAsTaggableOn::Tag.for_context(:collections).find(params[:id])
    @models = Model.tagged_with(@collection, context: :collection)

    # Ordering
    @models = case session["order"]
    when "recent"
      @models.order(created_at: :desc)
    else
      @models.order(name: :asc)
    end

    if current_user.pagination_settings["models"]
      page = params[:page] || 1
      @models = @models.page(page).per(current_user.pagination_settings["per_page"])
    end
  end
end
