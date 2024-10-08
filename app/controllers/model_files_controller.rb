class ModelFilesController < ApplicationController
  include ActionController::Live

  before_action :get_model
  before_action :get_file, except: [:create, :bulk_edit, :bulk_update]

  skip_after_action :verify_authorized, only: [:bulk_edit, :bulk_update]
  after_action :verify_policy_scoped, only: [:bulk_edit, :bulk_update]

  def show
    if stale?(@file)
      @duplicates = @file.duplicates
      respond_to do |format|
        format.html
        format.js
        format.any(*SupportedMimeTypes.indexable_types.map(&:to_sym)) do
          send_file_content disposition: (params[:download] == "true") ? :attachment : :inline
        end
      end
    end
  end

  def create
    authorize @model
    if params[:convert]
      file = ModelFile.find_param(params[:convert][:id])
      Analysis::FileConversionJob.perform_later(file.id, params[:convert][:to].to_sym)
      redirect_back_or_to [@model, file], notice: t(".conversion_started")
    elsif params[:uploads]
      uploads = begin
        JSON.parse(params[:uploads])[0]["successful"]
      rescue
        []
      end
      uploads.each do |upload|
        ProcessUploadedFileJob.perform_later(
          @model.library.id,
          upload["response"]["body"],
          model: @model
        )
      end
      redirect_to @model, notice: t(".success")
    else
      head :unprocessable_entity
    end
  end

  def update
    if @file.update(file_params)
      current_user.set_list_state(@file, :printed, params[:model_file][:printed] === "1")
      redirect_to [@model, @file], notice: t(".success")
    else
      render :edit, alert: t(".failure")
    end
  end

  def bulk_edit
    @files = policy_scope(ModelFile).where(model: @model).select(&:is_3d_model?)
  end

  def bulk_update
    hash = bulk_update_params
    ids_to_update = params[:model_files].keep_if { |key, value| value == "1" }.keys
    files = policy_scope(ModelFile).where(model: @model, public_id: ids_to_update)
    files.each do |file|
      ActiveRecord::Base.transaction do
        current_user.set_list_state(file, :printed, params[:printed] === "1")
        file.update(hash)
      end
    end
    if params[:split]
      new_model = @model.split! files: files
      redirect_to model_path(new_model), notice: t(".success")
    else
      redirect_back_or_to model_path(@model), notice: t(".success")
    end
  end

  def destroy
    authorize @file
    @file.delete_from_disk_and_destroy
    if request.referer && (URI.parse(request.referer).path == model_model_file_path(@model, @file))
      # If we're coming from the file page itself, we can't go back there
      redirect_to model_path(@model), notice: t(".success")
    else
      redirect_back_or_to model_path(@model), notice: t(".success")
    end
  end

  private

  def send_file_content(disposition: :attachment)
    # Check if we can send a direct URL
    redirect_to(@file.attachment.url, allow_other_host: true) if /https?:\/\//.match?(@file.attachment.url)
    # Otherwise provide a direct download
    status, headers, body = @file.attachment.to_rack_response(disposition: disposition)
    self.status = status
    self.headers.merge!(headers)
    self.response_body = body
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
      :y_up,
      :presupported_version_id
    ])
  end

  def get_model
    @model = Model.find_param(params[:model_id])
  end

  def get_file
    @file = @model.model_files.includes(:unsupported_version, :presupported_version).find_param(params[:id])
    authorize @file
    @title = @file.name
  end
end
