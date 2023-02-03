class ModelFilesController < ApplicationController
  before_action :get_library
  before_action :get_model
  before_action :get_file, except: [:bulk_edit, :bulk_update]

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
      format.abc { send_file_content }
      format.png { send_file File.join(@library.path, @model.path, @file.filename) }
      format.jpeg { send_file File.join(@library.path, @model.path, @file.filename) }
      format.svg { send_file File.join(@library.path, @model.path, @file.filename) }
      format.gif { send_file File.join(@library.path, @model.path, @file.filename) }
    end
  end

  def update
    @file.update(file_params)
    redirect_to [@library, @model, @file]
  end

  def bulk_edit
    @files = @model.model_files
  end

  def bulk_update
    hash = bulk_update_params
    params[:model_files].each_pair do |id, selected|
      if selected == "1"
        file = @model.model_files.find(id)
        if file.update(hash)
          file.save
        end
      end
    end
    redirect_to library_model_path(@library, @model)
  end

  def destroy
    @file.destroy
    redirect_to library_model_path(@library, @model)
  end

  private

  def send_file_content
    filename = File.join(@library.path, @model.path, @file.filename)
    response.headers["Content-Length"] = File.size(filename).to_s
    send_file filename, disposition: :inline, type: @file.file_format.to_sym
  rescue Errno::ENOENT
    head :internal_server_error
  end

  def bulk_update_params
    params.permit(
      :printed,
      :presupported,
      :y_up
    ).compact_blank
  end

  def file_params
    params.require(:model_file).permit([
      :printed,
      :presupported,
      :notes,
      :excerpt,
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
