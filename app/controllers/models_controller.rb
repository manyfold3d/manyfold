class ModelsController < ApplicationController
  before_action :get_library
  before_action :get_model

  def show
    @groups = helpers.group(@model.parts)
  end

  def edit
  end

  def update
    @model.update(model_params)
    redirect_to [@library, @model]
  end

  private

  def model_params
    params.require(:model).permit([
      :preview_part_id
    ])
  end

  def get_library
    @library = Library.find(params[:library_id])
  end

  def get_model
    @model = @library.models.find(params[:id])
  end
end
