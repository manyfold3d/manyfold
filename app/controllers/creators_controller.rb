class CreatorsController < ApplicationController
  include ModelFilters
  before_action :get_creator, except: [:index, :new, :create]

  def index
    process_filters_init
    process_filters_tags_fetchall
    process_filters
    process_filters_tags_highlight

    @creators = Creator.where(id: @models.map { |model| model.creator_id })

    # Ordering
    @creators = case session["order"]
    when "recent"
      @creators.order(created_at: :desc)
    else
      @creators.order(name: :asc)
    end

    if current_user.pagination_settings["creators"]
      page = params[:page] || 1
      @creators = @creators.page(page).per(current_user.pagination_settings["per_page"])
    end
  end

  def show
    redirect_to models_path(creator: params[:id])
  end

  def new
    @creator = Creator.new
    @creator.links.build if @creator.links.empty? # populate empty link
    @title = "New Creator"
  end

  def edit
    @creator.links.build if @creator.links.empty? # populate empty link
  end

  def create
    @creator = Creator.create(creator_params)
    redirect_to creators_path
  end

  def update
    @creator.update(creator_params)
    redirect_to creators_path
  end

  def destroy
    @creator.destroy
    redirect_to creators_path
  end

  private

  def get_creator
    if params[:id] == "0"
      @creator = nil
      @title = "Unknown"
    else
      @creator = Creator.find(params[:id])
      @title = @creator.name
    end
  end

  def creator_params
    params.require(:creator).permit([
      :name,
      :caption,
      :notes,
      links_attributes: [:id, :url, :_destroy]
    ])
  end
end
