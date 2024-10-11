class CollectionsController < ApplicationController
  include Filterable
  include TagListable
  include Permittable

  before_action :get_collection, except: [:index, :new, :create]

  def index
    @models = filtered_models @filters
    @collections = policy_scope(Collection)
    @collections = @collections.tree_both(Collection.find_param(@filters[:collection]).id || nil, @models.pluck(:collection_id).uniq) unless @filters[:collection].nil?

    @tags, @unrelated_tag_count = generate_tag_list(@models, @filter_tags)
    @tags, @kv_tags = split_key_value_tags(@tags)

    # Ordering
    @collections = case session["order"]
    when "recent"
      @collections.order(created_at: :desc)
    else
      @collections.order(name_lower: :asc)
    end

    if helpers.pagination_settings["collections"]
      page = params[:page] || 1
      @collections = @collections.page(page).per(helpers.pagination_settings["per_page"])
    end
    # Eager load
    @collections = @collections.includes :collections, :collection, :links, models: [:preview_file, :library]
    # Apply tag filters in-place
    @filter_in_place = true
    render layout: "card_list_page"
  end

  def show
    redirect_to models_path(collection: params[:id])
  end

  def new
    authorize Collection
    @collection = Collection.new
    @collection.links.build if @collection.links.empty? # populate empty link
    @collection.caber_relations.build if @collection.caber_relations.empty?
    @title = t("collections.general.new")
    @collections = Collection.all
  end

  def edit
    @collection.links.build if @collection.links.empty? # populate empty link
    @collection.caber_relations.build if @collection.caber_relations.empty?
    @collections = Collection.all
  end

  def create
    authorize Collection
    @collection = Collection.create(collection_params.merge(Collection.caber_owner(current_user)))
    if session[:return_after_new]
      redirect_to session[:return_after_new] + "?new_collection=#{@collection.to_param}", notice: t(".success")
      session[:return_after_new] = nil
    else
      redirect_to collections_path, notice: t(".success")
    end
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
      @collection = Collection.includes(:links, :caber_relations).find_param(params[:id])
      authorize @collection
      @title = @collection.name
    end
  end

  def collection_params
    params.require(:collection).permit(
      :name,
      :collection_id,
      :caption,
      :notes,
      links_attributes: [:id, :url, :_destroy]
    ).deep_merge(caber_relations_params(type: :collection))
  end
end
