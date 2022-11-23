class CollectionsController < ApplicationController
  def index
    @collections = ActsAsTaggableOn::Tag.for_context(:collections)
  end

  def show
    @collection = ActsAsTaggableOn::Tag.for_context(:collections).find(params[:id])
  end
end
