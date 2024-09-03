class CreatorsController < ApplicationController
  include Filterable
  include TagListable
  include Permittable

  before_action :get_creator, except: [:index, :new, :create]

  def index
    @creators = policy_scope(Creator)
    unless @filters.empty?
      @models = filtered_models @filters
      @creators = @creators.where(id: @models.map { |model| model.creator_id })
    end

    @tags, @unrelated_tag_count = generate_tag_list(@filters.empty? ? nil : @models, @filter_tags)
    @tags, @kv_tags = split_key_value_tags(@tags)

    # Ordering
    @creators = case session["order"]
    when "recent"
      @creators.order(created_at: :desc)
    else
      @creators.order(name: :asc)
    end

    if helpers.pagination_settings["creators"]
      page = params[:page] || 1
      @creators = @creators.page(page).per(helpers.pagination_settings["per_page"])
    end
    # Eager load data
    @creators = @creators.includes(:links, :models)
    render layout: "card_list_page"
  end

  def show
    redirect_to models_path(creator: params[:id])
  end

  def new
    authorize Creator
    @creator = Creator.new
    @creator.links.build if @creator.links.empty? # populate empty link
    @creator.caber_relations.build if @creator.caber_relations.empty?
    @title = t("creators.general.new")
  end

  def edit
    @creator.links.build if @creator.links.empty? # populate empty link
    @creator.caber_relations.build if @creator.caber_relations.empty?
  end

  def create
    authorize Creator
    @creator = Creator.create(creator_params)
    redirect_to creators_path, notice: t(".success")
  end

  def update
    @creator.update(creator_params)
    redirect_to @creator, notice: t(".success")
  end

  def destroy
    @creator.destroy
    redirect_to creators_path, notice: t(".success")
  end

  private

  def get_creator
    if params[:id] == "0"
      @creator = nil
      authorize Creator
      @title = t(".unknown")
    else
      @creator = Creator.includes(:links, :caber_relations).find(params[:id])
      authorize @creator
      @title = @creator.name
    end
  end

  def creator_params
    params.require(:creator).permit(
      :name,
      :caption,
      :notes,
      links_attributes: [:id, :url, :_destroy]
    ).deep_merge(caber_relations_params(type: :creator))
  end
end
