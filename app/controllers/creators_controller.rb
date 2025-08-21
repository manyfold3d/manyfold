class CreatorsController < ApplicationController
  include ModelListable
  include Permittable
  include LinkableController

  before_action :get_creator, except: [:index, :new, :create]
  before_action -> { set_indexable @creator }, except: [:index, :new, :create]

  def index
    @creators = policy_scope(Creator)
    @models = policy_scope(Model).all
    if @filter.any?
      @models = @filter.models(@models)
      @creators = @creators.where(id: @models.pluck(:creator_id).uniq)
    end

    @tags, @unrelated_tag_count = generate_tag_list(@models, @filter.tags)
    @tags, @kv_tags = split_key_value_tags(@tags)
    @unrelated_tag_count = nil unless @filter.any?

    # Ordering
    @creators = case session["order"]
    when "recent"
      @creators.order(created_at: :desc)
    else
      @creators.order(name_lower: :asc)
    end

    if helpers.pagination_settings["creators"]
      page = params[:page] || 1
      @creators = @creators.page(page).per(helpers.pagination_settings["per_page"])
    end
    # Eager load data
    @creators = @creators.includes(:links, :collections)
    # Apply tag filters in-place
    @filter_in_place = true

    # Count unassiged models
    @unassigned_count = policy_scope(Model).where(creator: nil).count
    set_indexable @creators

    respond_to do |format|
      format.html { render layout: "card_list_page" }
      format.manyfold_api_v0 { render json: ManyfoldApi::V0::CreatorListSerializer.new(@creators).serialize }
    end
  end

  def show
    respond_to do |format|
      format.html do
        @models = policy_scope(Model).where(creator: @creator)
        prepare_model_list
        @additional_filters = {creator: @creator}
        render layout: "card_list_page"
      end
      format.oembed { render json: OEmbed::CreatorSerializer.new(@creator, helpers.oembed_params).serialize }
      format.manyfold_api_v0 { render json: ManyfoldApi::V0::CreatorSerializer.new(@creator).serialize }
    end
  end

  def new
    authorize Creator
    @creator = Creator.new
    @title = t("creators.general.new")
  end

  def edit
  end

  def create
    authorize Creator
    @creator = Creator.create(creator_params.merge(Creator.caber_owner(current_user)))
    respond_to do |format|
      format.html do
        if @creator.valid?
          if session[:return_after_new]
            redirect_to session[:return_after_new] + "?new_creator=#{@creator.to_param}", notice: t(".success")
            session[:return_after_new] = nil
          else
            redirect_to creator_path(@creator), notice: t(".success")
          end
        else
          render :new, status: :unprocessable_content
        end
      end
      format.manyfold_api_v0 do
        if @creator.valid?
          render json: ManyfoldApi::V0::CreatorSerializer.new(@creator).serialize, status: :created, location: creator_path(@creator)
        else
          render json: @creator.errors.to_json, status: :unprocessable_content
        end
      end
    end
  end

  def update
    @creator.update(creator_params)
    respond_to do |format|
      format.html do
        if @creator.valid?
          redirect_to @creator, notice: t(".success")
        else
          # Restore previous slug
          @attemped_slug = @creator.slug
          @creator.slug = @creator.slug_was
          render :edit, status: :unprocessable_content
        end
      end
      format.manyfold_api_v0 do
        if @creator.valid?
          render json: ManyfoldApi::V0::CreatorSerializer.new(@creator).serialize
        else
          render json: @creator.errors.to_json, status: :unprocessable_content
        end
      end
    end
  end

  def destroy
    @creator.destroy
    respond_to do |format|
      format.html { redirect_to creators_path, notice: t(".success") }
      format.manyfold_api_v0 { head :no_content }
    end
  end

  private

  def get_creator
    if params[:id] == "0"
      @creator = nil
      authorize Creator
      @title = t(".unknown")
    else
      @creator = @linkable = policy_scope(Creator).find_param(params[:id])
      authorize @creator
      @title = @creator.name
    end
  end

  def creator_params
    if is_api_request?
      raise ActionController::BadRequest unless params[:json]
      ManyfoldApi::V0::CreatorDeserializer.new(params[:json]).deserialize
    else
      Form::CreatorDeserializer.new(params).deserialize
    end
  end
end
