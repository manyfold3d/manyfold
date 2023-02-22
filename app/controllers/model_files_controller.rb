class ModelFilesController < ApplicationController
  before_action :get_library
  before_action :get_model
  before_action :get_file, except: [:bulk_edit, :bulk_update]

  def show
    respond_to do |format|
      format.html
      format.js
      format.any(*SupportedMimeTypes.model_types) do
        send_file_content
      end
      format.any(*SupportedMimeTypes.image_types) do
        send_file File.join(@library.path, @model.path, @file.filename)
      end
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
    send_file filename, disposition: :inline, type: @file.extension.to_sym
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
      :caption,
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
