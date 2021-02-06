class ModelsController < ApplicationController
  def show
    @library = Library.find(params[:library_id])
    @model = @library.models.find(params[:id])
    @groups = @model.parts.group_by{ |i| i.filename.split(/[\ _\-:\.]/)[0] }
  end
end
