class CollectionsController < ApplicationController
  include Filterable
  include TagListable
  include Permittable
  include ModelListable

  allow_api_access only: [:index, :show], scope: [:read, :public]
  allow_api_access only: [:create, :update], scope: :write
  allow_api_access only: :destroy, scope: :delete

  before_action :get_collection, except: [:index, :new, :create]
  before_action :get_creators, except: [:index, :create]

  def index
    @models = filtered_models @filters
    @collections = policy_scope(Collection)
    @collections = filtered_collections @filters

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
    @collections = @collections.includes :collections, :collection, :links
    # Apply tag filters in-place
    @filter_in_place = true

    # Count unassiged models
    @unassigned_count = policy_scope(Model).where(collection: nil).count

    respond_to do |format|
      format.html { render layout: "card_list_page" }
      format.manyfold_api_v0 { render json: ManyfoldApi::V0::CollectionListSerializer.new(@collections).serialize }
    end
  end

  def show
    respond_to do |format|
      format.html do
        @models = policy_scope(Model).where(collection: @collection)
        prepare_model_list
        @additional_filters = {collection: @collection}
        render layout: "card_list_page"
      end
      format.oembed { render json: OEmbed::CollectionSerializer.new(@collection, helpers.oembed_params).serialize }
      format.manyfold_api_v0 { render json: ManyfoldApi::V0::CollectionSerializer.new(@collection).serialize }
    end
  end

  def new
    authorize Collection
    @collection = Collection.new
    @collection.links.build if @collection.links.empty? # populate empty link
    @collection.caber_relations.build if @collection.caber_relations.empty?
    @title = t("collections.general.new")
    @collections = policy_scope(Collection).all
  end

  def edit
    @collection.links.build if @collection.links.empty? # populate empty link
    @collection.caber_relations.build if @collection.caber_relations.empty?
    @collections = policy_scope(Collection).all
  end

  def create
    authorize Collection
    @collection = Collection.create(collection_params.merge(Collection.caber_owner(current_user)))
    respond_to do |format|
      format.html do
        if session[:return_after_new]
          redirect_to session[:return_after_new] + "?new_collection=#{@collection.to_param}", notice: t(".success")
          session[:return_after_new] = nil
        else
          redirect_to collections_path, notice: t(".success")
        end
      end
      format.manyfold_api_v0 do
        if @collection.valid?
          render json: ManyfoldApi::V0::CollectionSerializer.new(@collection).serialize, status: :created, location: collection_path(@collection)
        else
          render json: @collection.errors.to_json, status: :bad_request
        end
      end
    end
  end

  def update
    @collection.update(collection_params)
    respond_to do |format|
      format.html do
        redirect_to collections_path, notice: t(".success")
      end
      format.manyfold_api_v0 do
        if @collection.valid?
          render json: ManyfoldApi::V0::CollectionSerializer.new(@collection).serialize
        else
          render json: @collection.errors.to_json, status: :bad_request
        end
      end
    end
  end

  def destroy
    @collection.destroy
    respond_to do |format|
      format.html { redirect_to collections_path, notice: t(".success") }
      format.manyfold_api_v0 { head :no_content }
    end
  end

  private

  def get_collection
    if params[:id] == "0"
      @collection = nil
      authorize Collection
      @title = t(".unknown")
    else
      @collection = policy_scope(Collection).find_param(params[:id])
      authorize @collection
      @title = @collection.name
    end
  end

  def get_creators
    @creators = policy_scope(Creator).order("LOWER(name) ASC")
  end

  def collection_params
    if is_api_request?
      raise ActionController::BadRequest unless params[:json]
      return ManyfoldApi::V0::CollectionDeserializer.new(params[:json]).deserialize
    end
    params.require(:collection).permit(
      :name,
      :creator_id,
      :collection_id,
      :caption,
      :notes,
      links_attributes: [:id, :url, :_destroy]
    ).deep_merge(caber_relations_params(type: :collection))
  end
end
