class ModelFilesController < ApplicationController
  include ActionController::Live

  before_action :get_model
  before_action :get_file, except: [:create, :bulk_edit, :bulk_update]
  before_action -> { set_indexable @file }, except: [:create, :bulk_edit, :bulk_update]

  skip_after_action :verify_authorized, only: [:bulk_edit, :bulk_update]
  after_action :verify_policy_scoped, only: [:bulk_edit, :bulk_update]

  def configure_content_security_policy
    # If embed mode, allow any frame ancestor
    content_security_policy.frame_ancestors [:https, :http] if embedded?
  end

  def show
    if embedded?
      respond_to do |format|
        format.html { render "embedded", layout: "embed" }
      end
    elsif stale?(@file)
      @duplicates = @file.duplicates
      respond_to do |format|
        format.html
        format.manyfold_api_v0 { render json: ManyfoldApi::V0::ModelFileSerializer.new(@file).serialize }
        format.any(*SupportedMimeTypes.indexable_types.map(&:to_sym)) do
          attachment = @file.attachment(params[:derivative]) || @file.attachment
          send_file_content attachment, derivative: params[:derivative], disposition: (params[:download] == "true") ? :attachment : :inline
        end
      end
    end
  end

  def create
    authorize @model
    if params[:convert]
      file = ModelFile.find_param(params[:convert][:id])
      file.convert_later params[:convert][:to]
      redirect_back_or_to [@model, file], notice: t(".conversion_started")
    elsif !(p = upload_params).empty?
      p.dig(:model, :file).each_pair do |_id, file|
        ProcessUploadedFileJob.perform_later(
          @model.library.id,
          {
            id: file[:id],
            storage: "cache",
            metadata: {
              filename: file[:name]
            }
          },
          model: @model
        )
      end
      respond_to do |format|
        format.html { redirect_to @model, notice: t(".success") }
        format.manyfold_api_v0 { head :accepted }
      end
    else
      head :unprocessable_content
    end
  end

  def update
    result = @file.update(file_params)
    respond_to do |format|
      format.html do
        if result
          current_user.set_list_state(@file, :printed, params[:model_file][:printed] === "1")
          redirect_to [@model, @file], notice: t(".success")
        else
          render :edit, alert: t(".failure"), status: :unprocessable_content
        end
      end
      format.manyfold_api_v0 do
        if result
          render json: ManyfoldApi::V0::ModelFileSerializer.new(@file).serialize
        else
          render json: @file.errors.to_json, status: :unprocessable_content
        end
      end
    end
  end

  def bulk_edit
    @files = policy_scope(@model.model_files.without_special)
  end

  def bulk_update
    hash = bulk_update_params
    ids_to_update = params[:model_files].keep_if { |key, value| value == "1" }.keys
    files = policy_scope(@model.model_files.without_special).where(public_id: ids_to_update)
    files.each do |file|
      ActiveRecord::Base.transaction do
        current_user.set_list_state(file, :printed, params[:printed] === "1")
        options = {}
        if params[:pattern].present?
          options[:filename] =
            file.filename.split(file.extension).first.gsub(params[:pattern], params[:replacement]) +
            file.extension
        end
        file.update(hash.merge(options))
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
    respond_to do |format|
      format.html do
        if request.referer && (URI.parse(request.referer).path == model_model_file_path(@model, @file))
          # If we're coming from the file page itself, we can't go back there
          redirect_to model_path(@model), notice: t(".success")
        else
          redirect_back_or_to model_path(@model), notice: t(".success")
        end
      end
      format.manyfold_api_v0 { head :no_content }
    end
  end

  private

  def bulk_update_params
    params.permit(
      :presupported,
      :y_up,
      :previewable
    ).compact_blank
  end

  def file_params
    if is_api_request?
      raise ActionController::BadRequest unless params[:json]
      ManyfoldApi::V0::ModelFileDeserializer.new(params[:json]).deserialize
    else
      Form::ModelFileDeserializer.new(params).deserialize
    end
  end

  def upload_params
    if is_api_request?
      raise ActionController::BadRequest unless params[:json]
      ManyfoldApi::V0::UploadedFileDeserializer.new(params[:json]).deserialize
    else
      Form::UploadedFileDeserializer.new(params).deserialize
    end
  end

  def get_model
    @model = Model.find_param(params[:model_id])
  end

  def get_file
    scope = @model.model_files
    begin
      @file = scope.find_param(params[:id])
    rescue ActiveRecord::RecordNotFound
      @file = scope.find_by!(filename: [params[:id], params[:format]].join("."))
      request.format = params[:format].downcase
    end
    # Check for signed download URLs
    if has_signed_id?
      @signed_file = @model.model_files.find_signed!(params[:sig], purpose: "download")
      if @file == @signed_file
        skip_authorization
      else
        raise ActiveRecord::RecordNotFound
      end
    else
      authorize @file
    end
    @title = @file.name
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    raise ActiveRecord::RecordNotFound
  end

  def embedded?
    params[:embed] == "true"
  end
end
