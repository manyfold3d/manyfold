class ModelFilesController < ApplicationController
  before_action :get_library
  before_action :get_model
  before_action :get_file, except: [:bulk_edit, :bulk_update]

  def show
    if stale?(@file)
      @duplicates = @file.duplicates
      respond_to do |format|
        format.html
        format.js
        format.any(*SupportedMimeTypes.model_types.map(&:to_sym)) do
          send_file_content
        end
        format.any(*SupportedMimeTypes.image_types.map(&:to_sym)) do
          send_file File.join(@library.path, @model.path, @file.filename)
        end
      end
    end
  end

  def update
    @file.update(file_params)
    @file.set_printed_by_user(current_user, params[:model_file][:printed] === "1")
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
        file.set_printed_by_user(current_user, params[:printed] === "1")
        if file.update(hash)
          file.save
        end
      end
    end
    redirect_to library_model_path(@library, @model)
  end

  def destroy
    authorize @file
    @file.delete_from_disk_and_destroy
    redirect_to library_model_path(@library, @model)
  end

  private

  def send_file_content
    filename = File.join(@library.path, @model.path, @file.filename)
    redirect_to "/files/#{filename}", allow_other_host: true
  rescue Errno::ENOENT
    head :internal_server_error
  end

  def bulk_update_params
    params.permit(
      :presupported,
      :y_up
    ).compact_blank
  end

  def file_params
    params.require(:model_file).permit([
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
