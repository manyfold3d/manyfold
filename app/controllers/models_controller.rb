require "fileutils"

class ModelsController < ApplicationController
  include ModelListable
  include Permittable
  include LinkableController

  rate_limit to: 10, within: 3.minutes, only: :create

  before_action :redirect_search, only: [:index], if: -> { params.key?(:q) }
  before_action :get_creators_and_collections, only: [:new, :edit, :bulk_edit]
  before_action :set_returnable, only: [:bulk_edit, :edit, :new]
  before_action :clear_returnable, only: [:bulk_update, :update, :create]
  before_action :get_filters, only: [:bulk_edit, :bulk_update, :index, :show] # rubocop:todo Rails/LexicallyScopedActionFilter
  before_action :get_model, except: [:bulk_edit, :bulk_update, :index, :new, :create]
  before_action -> { set_indexable @model if @model }

  after_action :verify_policy_scoped, only: [:bulk_edit, :bulk_update]

  include ModelsController::Merge

  def index
    @models = @filter.models(policy_scope(Model))
    @search = params[:q].presence
    prepare_model_list
    set_indexable @models
    respond_to do |format|
      format.html { render layout: "card_list_page" }
      format.manyfold_api_v0 { render json: ManyfoldApi::V0::ModelListSerializer.new(@models).serialize }
    end
  end

  def show
    respond_to do |format|
      format.html do
        files = policy_scope(@model.model_files).without_special
        @locked_files = @model.model_files.without_special.count - files.count
        @images = files.select(&:is_image?)
        @images.unshift(@model.preview_file) if @images.delete(@model.preview_file)
        if helpers.file_list_settings["hide_presupported_versions"]
          hidden_ids = files.select(:presupported_version_id).where.not(presupported_version_id: nil)
          files = files.where.not(id: hidden_ids)
        end
        files = files.includes(:presupported_version, :problems)
        files = files.reject(&:is_image?)
        @groups = helpers.group(files)
        @num_files = files.count
      end
      format.zip do
        download = ArchiveDownloadService.new(model: @model, selection: params[:selection])
        if download.ready?
          send_file(download.output_file, filename: download.filename, type: :zip, disposition: :attachment)
        elsif download.preparing?
          redirect_to model_path(@model, format: :html), notice: t(".download_preparing")
        else
          download.prepare
          redirect_to model_path(@model, format: :html), notice: t(".download_requested")
        end
      end
      format.oembed { render json: OEmbed::ModelSerializer.new(@model, helpers.oembed_params).serialize }
      format.manyfold_api_v0 { render json: ManyfoldApi::V0::ModelSerializer.new(@model).serialize }
    end
  end

  def new
    @model = Model.new # dummy model object
    authorize :model
    generate_available_tag_list
  end

  def edit
    @model.links.build if @model.links.empty? # populate empty link
    @model.caber_relations.build if @model.caber_relations.empty?
    generate_available_tag_list
  end

  def create
    authorize :model
    p = upload_params
    # First, is this a single or multi-model event?
    multiple = p[:file]&.values&.all? { |it| SupportedMimeTypes.archive_extensions.include? File.extname(it[:name]).delete(".").downcase }
    # Then run validations on a dummy object
    common_args = {
      name: multiple ? nil : p[:name],
      owner: current_user,
      creator_id: p[:creator_id],
      collection_id: p[:collection_id],
      license: p[:license],
      sensitive: (p[:sensitive] == "1"),
      tag_list: p[:tag_list],
      permission_preset: p[:permission_preset]
    }.compact
    library = SiteSettings.show_libraries ? Library.find_param(p[:library]) : Library.default
    @model = Model.new(common_args.merge(library: library)) # dummy model object
    if @model.valid?(multiple ? :multi_upload : :single_upload)
      # Handle actual files
      jobs = if multiple
        # If this is all separate archives, enqueue separate jobs for each
        p[:file].values.map { |it| cached_file_data(it) }
      else
        # Otherwise, enqueue one job for all files and add name to args
        [p[:file].values.map { |it| cached_file_data(it) }]
      end
      jobs.each do |it|
        ProcessUploadedFileJob.perform_later(library.id, it, **common_args)
      end
      respond_to do |format|
        format.html { redirect_to models_path, notice: t(".success") }
        format.manyfold_api_v0 { head :accepted }
      end
    else
      get_creators_and_collections
      generate_available_tag_list
      respond_to do |format|
        format.html { render :new, status: :unprocessable_content }
        format.manyfold_api_v0 { render json: @model.errors.to_json, status: :unprocessable_content }
      end
    end
  end

  def update
    hash = model_params
    organize = hash.delete(:organize) == "true"
    result = @model.update(hash)
    respond_to do |format|
      format.html do
        if result
          @model.organize_later if organize
          redirect_to @model, notice: t(".success")
        else
          get_creators_and_collections
          edit
          render :edit, status: :unprocessable_content
        end
      end
      format.manyfold_api_v0 do
        if result
          render json: ManyfoldApi::V0::ModelSerializer.new(@model).serialize
        else
          render json: @model.errors.to_json, status: :unprocessable_content
        end
      end
    end
  end

  def scan
    # Start the scans
    @model.check_later
    # Back to the model page
    redirect_to @model, notice: t(".success")
  end

  def bulk_edit
    authorize Model
    @models = @filter.models(policy_scope(Model, policy_scope_class: ApplicationPolicy::UpdateScope)).includes(:collection, :creator)
    generate_available_tag_list
    if helpers.pagination_settings["models"]
      page = params[:page] || 1
      # Double the normal page size for bulk editing
      @models = @models.page(page).per(helpers.pagination_settings["per_page"] * 2)
    end
    set_indexable @models
    # Apply tag filters in-place
    @filter_in_place = true
  end

  def bulk_update
    authorize Model
    hash = bulk_update_params
    hash[:library_id] = hash.delete(:new_library_id) if hash[:new_library_id]
    add_tags = Set.new(hash.delete(:add_tags))
    remove_tags = Set.new(hash.delete(:remove_tags))

    models_to_update = if params.key?(:update_all)
      # If "Update All Models" was clicked, update all models in the filtered set
      @filter.models(policy_scope(Model, policy_scope_class: ApplicationPolicy::UpdateScope))
    else
      # If "Update Selected Models" was clicked, only update checked models
      ids = params[:models].select { |k, v| v == "1" }.keys
      policy_scope(Model, policy_scope_class: ApplicationPolicy::UpdateScope).where(public_id: ids)
    end

    models_to_update.find_each do |model|
      if model&.update(hash)
        existing_tags = Set.new(model.tag_list)
        model.tag_list = existing_tags + add_tags - remove_tags
        model.save
      end
    end
    redirect_back_or_to edit_models_path(@filter.to_params), notice: t(".success")
  end

  def destroy
    @model.delete_from_disk_and_destroy
    respond_to do |format|
      format.html do
        if request.referer && (URI.parse(request.referer).path == model_path(@model))
          # If we're coming from the model page itself, we can't go back there
          redirect_to root_path, notice: t(".success")
        else
          redirect_back_or_to root_path, notice: t(".success")
        end
      end
      format.manyfold_api_v0 { head :no_content }
    end
  end

  private

  def redirect_search
    redirect_to new_follow_path(uri: params[:q]) if params[:q]&.match?(/(@|acct:)?([a-z0-9\-_.]+)@(.*)/)
    if params[:q]&.match?(URI::RFC2396_PARSER.make_regexp)
      if (link = Link.find_by(url: params[:q]))
        redirect_to link.linkable
      elsif Link.deserializer_for(url: params[:q])
        redirect_to new_import_path(url: params[:q])
      end
    end
  end

  def generate_available_tag_list
    @available_tags = policy_scope(ActsAsTaggableOn::Tag).where(
      id: policy_scope(ActsAsTaggableOn::Tagging).where(
        taggable_type: "Model", taggable_id: policy_scope(Model).select(:id)
      ).select(:tag_id)
    ).order(:name)
  end

  def bulk_update_params
    params.permit(
      :creator_id,
      :collection_id,
      :new_library_id,
      :organize,
      :license,
      :sensitive,
      add_tags: [],
      remove_tags: []
    ).compact_blank
  end

  def model_params
    if is_api_request?
      raise ActionController::BadRequest unless params[:json]
      ManyfoldApi::V0::ModelDeserializer.new(params[:json]).deserialize
    else
      Form::ModelDeserializer.new(params).deserialize
    end
  end

  def upload_params
    if is_api_request?
      raise ActionController::BadRequest unless params[:json]
      ManyfoldApi::V0::UploadedModelDeserializer.new(params[:json]).deserialize
    else
      Form::UploadedModelDeserializer.new(params).deserialize
    end
  end

  def get_model
    @model = @linkable = policy_scope(Model).find_param(params[:id])
    authorize @model
    @title = @model.name
  end

  def get_creators_and_collections
    # Creators and collections that we can assign this model to
    @creators = policy_scope(Creator, policy_scope_class: ApplicationPolicy::UpdateScope).local.order("LOWER(creators.name) ASC")
    @default_creator = @creators.first if @creators.count == 1
    @collections = policy_scope(Collection, policy_scope_class: ApplicationPolicy::UpdateScope).local.order("LOWER(collections.name) ASC")
  end

  def set_returnable
    session[:return_after_new] = request.fullpath.split("?")[0]
    @new_collection = Collection.find_param(params[:new_collection]) if params[:new_collection]
    @new_creator = Creator.find_param(params[:new_creator]) if params[:new_creator]
    if @model
      @model.collection = @new_collection if @new_collection
      @model.creator = @new_creator if @new_creator
    end
  end

  def clear_returnable
    session[:return_after_new] = nil
  end

  def cached_file_data(file)
    {
      id: file[:id],
      storage: "cache",
      metadata: {
        filename: file[:name]
      }
    }
  end
end
