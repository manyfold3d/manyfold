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

  def update
    @library = Library.find(params[:library_id])
    @model = @library.models.find(params[:model_id])
    @part = @model.parts.find(params[:id])
    @part.update(part_params)
    redirect_to [@library, @model, @part]
  end

  private

  def part_params
    params.require(:part).permit([
      :printed,
      :presupported,
    ])
  end

end
