class PartsController < ApplicationController
  before_action :get_library
  before_action :get_model
  before_action :get_part

  def show
    respond_to do |format|
      format.html
      format.js
      format.stl { send_file_content }
      format.obj { send_file_content }
      format.threemf { send_file_content }
      format.ply { send_file_content }
      format.blend { send_file_content }
      format.mix { send_file_content }
    end
  end

  def update
    @part.update(part_params)
    redirect_to [@library, @model, @part]
  end

  private

  def send_file_content
    filename = File.join(@library.path, @model.path, @part.filename)
    response.headers["Content-Length"] = File.size(filename).to_s
    send_file filename, disposition: :inline, type: @part.file_format.to_sym
  rescue Errno::ENOENT
    head :internal_server_error
  end

  def part_params
    params.require(:part).permit([
      :printed,
      :presupported,
      :y_up
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
    @title = @part.name
  end
end
