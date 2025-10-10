class CollectionsController < ApplicationController
  include Filterable
  include TagListable
  include Permittable
  include ModelListable
  include LinkableController

  before_action :get_collection, except: [:index, :new, :create]
  before_action :get_parent_collections, except: [:index, :create]
  before_action :get_creators, except: [:index, :create]
  before_action -> { set_indexable @collection }, except: [:index, :new, :create]

  def index
    @models = policy_scope(Model).all
    @collections = policy_scope(Collection).all
    if @filter.any?
      @models = @filter.models(@models)
      @collections = @filter.collections(@collections)
    end

    @tags, @unrelated_tag_count = generate_tag_list(@models, @filter.tags)
    @tags, @kv_tags = split_key_value_tags(@tags)
    @unrelated_tag_count = nil unless @filter.any?

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
    set_indexable @collections
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
    @title = t("collections.general.new")
  end

  def edit
  end

  def create
    authorize Collection
    @collection = Collection.create(collection_params.merge(owner: current_user))
    respond_to do |format|
      format.html do
        if @collection.valid?
          if session[:return_after_new]
            redirect_to session[:return_after_new] + "?new_collection=#{@collection.to_param}", notice: t(".success")
            session[:return_after_new] = nil
          else
            redirect_to collections_path, notice: t(".success")
          end
        else
          render :new, status: :unprocessable_content
        end
      end
      format.manyfold_api_v0 do
        if @collection.valid?
          render json: ManyfoldApi::V0::CollectionSerializer.new(@collection).serialize, status: :created, location: collection_path(@collection)
        else
          render json: @collection.errors.to_json, status: :unprocessable_content
        end
      end
    end
  end

  def update
    @collection.update(collection_params)
    respond_to do |format|
      format.html do
        if @collection.valid?
          redirect_to collections_path, notice: t(".success")
        else
          render :edit, status: :unprocessable_content
        end
      end
      format.manyfold_api_v0 do
        if @collection.valid?
          render json: ManyfoldApi::V0::CollectionSerializer.new(@collection).serialize
        else
          render json: @collection.errors.to_json, status: :unprocessable_content
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
      @collection = @linkable = policy_scope(Collection).find_param(params[:id])
      authorize @collection
      @title = @collection.name
    end
  end

  def get_creators
    # Creators that we can assign this collection to
    @creators = policy_scope(Creator, policy_scope_class: ApplicationPolicy::UpdateScope).local.order("LOWER(creators.name) ASC")
    @default_creator = @creators.first if @creators.count == 1
  end

  def get_parent_collections
    # Collection that we can add this one to
    @collections = policy_scope(Collection, policy_scope_class: ApplicationPolicy::UpdateScope).local.where.not(id: @collection&.id).order("LOWER(collections.name) ASC")
  end

  def collection_params
    if is_api_request?
      raise ActionController::BadRequest unless params[:json]
      ManyfoldApi::V0::CollectionDeserializer.new(params[:json]).deserialize
    else
      Form::CollectionDeserializer.new(params).deserialize
    end
  end
end
