class PartsController < ApplicationController
  def show
    @library = Library.find(params[:library_id])
    @model = @library.models.find(params[:model_id])
    @part = @model.parts.find(params[:id])
    respond_to do |format|
      format.html
      format.js
      format.stl { send_file File.join(@library.path, @model.path, @part.filename) }
      format.obj { send_file File.join(@library.path, @model.path, @part.filename) }
    end
  end
end
