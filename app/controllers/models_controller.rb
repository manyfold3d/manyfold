class ModelsController < ApplicationController
  def show
    @library = Library.find(params[:library_id])
    @model = @library.models.find(params[:id])
    @groups = helpers.group(@model.parts)
  end
end
