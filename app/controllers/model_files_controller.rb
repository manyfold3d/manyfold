class ModelFilesController < ApplicationController
  before_action :get_library
  before_action :get_model
  before_action :get_file

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
      format.png { send_file File.join(@library.path, @model.path, @file.filename) }
      format.jpeg { send_file File.join(@library.path, @model.path, @file.filename) }
    end
  end

  def update
    @file.update(file_params)
    redirect_to [@library, @model, @file]
  end

  private

  def send_file_content
    filename = File.join(@library.path, @model.path, @file.filename)
    response.headers["Content-Length"] = File.size(filename).to_s
    send_file filename, disposition: :inline, type: @file.file_format.to_sym
  rescue Errno::ENOENT
    head :internal_server_error
  end

  def file_params
    params.require(:model_file).permit([
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

  def get_file
    @file = @model.model_files.find(params[:id])
    @title = @file.name
  end
end
