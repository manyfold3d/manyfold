class CollectionsController < ApplicationController
  include ModelFilters
  before_action :get_collection, except: [:index, :new, :create]

  def index
    process_filters_init
    process_filters_tags_fetchall
    process_filters
    process_filters_tags_highlight

    # @collections = Collection.where(id: @models.map{|model| model.collection_id})
    @collections = Collection.tree_both(@filters[:collection]||nil,@models.map{|model| model.collection_id}.compact)

    # Ordering
    @collections = case session["order"]
    when "recent"
      @collections.order(created_at: :desc)
    else
      @collections.order(name: :asc)
    end

    if current_user.pagination_settings["collections"]
      page = params[:page] || 1
      @collections = @collections.page(page).per(current_user.pagination_settings["per_page"])
    end
  end

  def show
    redirect_to models_path(collection: params[:id])
  end

  def new
    @collection = Collection.new
    @collection.links.build if @collection.links.empty? # populate empty link
    @title = "New Collection"
    @collections = Collection.all
  end

  def edit
    @collection.links.build if @collection.links.empty? # populate empty link
    @collections = Collection.all
  end

  def create
    @collection = Collection.create(collection_params)
    redirect_to collections_path
  end

  def update
    @collection.update(collection_params)
    redirect_to collections_path
  end

  def destroy
    @collection.destroy
    redirect_to collections_path
  end

  private

  def get_collection
    if params[:id] == "0"
      @collection = nil
      @title = "Unknown"
    else
      @collection = Collection.find(params[:id])
      @title = @collection.name
    end
  end

  def collection_params
    params.require(:collection).permit([
      :name,
      :collection_id,
      :caption,
      :notes,
      links_attributes: [:id, :url, :_destroy]
    ])
  end
end
