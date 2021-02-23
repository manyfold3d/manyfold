class ModelsController < ApplicationController
  def show
    @library = Library.find(params[:library_id])
    @model = @library.models.find(params[:id])
    @groups = helpers.group(@model.parts)
  end

  def update
    @library = Library.find(params[:library_id])
    @model = @library.models.find(params[:id])
    @model.update(model_params)
    redirect_to [@library, @model]
  end

  private

  def model_params
    params.require(:model).permit([
      :preview_part_id
    ])
  end
end
