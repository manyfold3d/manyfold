class CollectionsController < ApplicationController
  include ModelFilters
  before_action :get_collection, except: [:index, :new, :create]

  def index
    @collections = policy_scope(Collection)
    if @filters.empty?
      @commontags = @tags = ActsAsTaggableOn::Tag.all
    else
      process_filters_init
      process_filters_tags_fetchall
      process_filters
      process_filters_tags_highlight
      @collections = @collections.tree_both(@filters[:collection] || nil, @models.filter_map { |model| model.collection_id })
    end

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
    # Eager load
    @collections = @collections.includes :collections, :collection, :links, :models
    render layout: "card_list_page"
  end

  def show
    redirect_to models_path(collection: params[:id])
  end

  def new
    authorize Collection
    @collection = Collection.new
    @collection.links.build if @collection.links.empty? # populate empty link
    @title = t("collections.general.new")
    @collections = Collection.all
  end

  def edit
    @collection.links.build if @collection.links.empty? # populate empty link
    @collections = Collection.all
  end

  def create
    authorize Collection
    @collection = Collection.create(collection_params)
    redirect_to collections_path, notice: t(".success")
  end

  def update
    @collection.update(collection_params)
    redirect_to collections_path, notice: t(".success")
  end

  def destroy
    @collection.destroy
    redirect_to collections_path, notice: t(".success")
  end

  private

  def get_collection
    if params[:id] == "0"
      @collection = nil
      authorize Collection
      @title = t(".unknown")
    else
      @collection = Collection.find(params[:id])
      authorize @collection
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
