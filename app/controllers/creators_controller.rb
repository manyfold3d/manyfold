class CreatorsController < ApplicationController
  before_action :get_creator, except: [:index, :new, :create]

  def index
    @creators = Creator.all
  end

  def show
    @models = @creator.models
  end

  def edit
  end

  def update
    @creator.update(creator_params)
    redirect_to @creator
  end

  def new
    @creator = Creator.new
  end

  def create
    @creator = Creator.create(creator_params)
    redirect_to @creator
  end

  def destroy
    @creator.destroy
    redirect_to creators_path
  end

  private

  def get_creator
    @creator = Creator.find(params[:id])
  end

  def creator_params
    params.require(:creator).permit([
      :name,
      links_attributes: [:id, :url, :_destroy]
    ])
  end
end
