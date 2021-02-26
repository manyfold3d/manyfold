class PartsController < ApplicationController
  before_action :get_library
  before_action :get_model
  before_action :get_part

  def show
    respond_to do |format|
      format.html
      format.js
      format.stl { send_file File.join(@library.path, @model.path, @part.filename) }
      format.obj { send_file File.join(@library.path, @model.path, @part.filename) }
    end
  end

  def update
    @part.update(part_params)
    redirect_to [@library, @model, @part]
  end

  private

  def part_params
    params.require(:part).permit([
      :printed,
      :presupported
    ])
  end

  def get_library
    @library = Library.find(params[:library_id])
  end

  def get_model
    @model = @library.models.find(params[:model_id])
  end

  def get_part
    @part = @model.parts.find(params[:id])
  end
end
