class CreatorsController < ApplicationController
  before_action :get_creator, except: [:index, :new, :create]

  def index
    @creators = Creator.all
  end

  def show
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
      :thingiverse_user,
      :cgtrader_user,
      :cults3d_user,
      :mmf_user
    ])
  end
end
