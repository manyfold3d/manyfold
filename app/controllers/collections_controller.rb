class CollectionsController < ApplicationController
  before_action :get_collection, except: [:index, :new, :create]

  def index
    @collections =
      if current_user.pagination_settings["collections"]
        page = params[:page] || 1
        Collection.all.page(page).per(current_user.pagination_settings["per_page"])
      else
        Collection.all
      end
    @title = "Collections"
  end

  def show
    redirect_to models_path(collection: params[:id])
  end

  def new
    @collection = Collection.new
    @collection.links.build if @collection.links.empty? # populate empty link
    @title = "New Collection"
  end

  def edit
    @collection.links.build if @collection.links.empty? # populate empty link
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
      :caption,
      :notes,
      links_attributes: [:id, :url, :_destroy]
    ])
  end
end
