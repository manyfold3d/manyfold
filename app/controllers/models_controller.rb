require "fileutils"

class ModelsController < ApplicationController
  include ModelListable
  include Permittable
  include LinkableController

  rate_limit to: 10, within: 3.minutes, only: :create

  before_action :redirect_search, only: [:index], if: -> { params.key?(:q) }
  before_action :get_creators_and_collections, only: [:new, :edit, :bulk_edit]
  before_action :set_returnable, only: [:bulk_edit, :edit, :new]
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
          hidden_ids = files.includes(:relationships).where("relationships.predicate": ["supported_version_of", "alternative_format_of"])
          files = files.where.not(id: hidden_ids)
        end
        files = files.includes(:problems)
        files = files.reject(&:is_image?)
        @groups = helpers.group(files)
        @num_files = files.count
      end
      format.zip do
        if policy(@model).download?
          download = ArchiveDownloadService.new(model: @model, selection: params[:selection])
          if download.ready?
            send_file(download.output_file, filename: download.filename, type: :zip, disposition: :attachment)
          elsif download.preparing?
            redirect_to model_path(@model, format: :html), notice: t(".download_preparing")
          else
            download.prepare
            redirect_to model_path(@model, format: :html), notice: t(".download_requested")
          end
        else
          head :forbidden
        end
      end
      format.oembed { render json: OEmbed::ModelSerializer.new(@model, helpers.oembed_params).serialize }
      format.manyfold_api_v0 { render json: ManyfoldApi::V0::ModelSerializer.new(@model).serialize }
    end
    # i18n-tasks-use t("activerecord.attributes.model.path")
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
    num_files = p[:file].keys.count
    multi_model = (num_files > 1) && p[:file]&.values&.all? { is_archive?(it) }
    # Then run validations on a dummy object
    common_attributes = {
      name: multi_model ? nil : (p[:name]&.presence || File.basename(p.dig(:file, "0", :name), ".*").careful_titleize),
      owner: current_user,
      creator_id: p[:creator_id],
      collection_ids: p[:collections]&.map(&:id),
      license: p[:license],
      sensitive: (p[:sensitive] == "1"),
      tag_list: p[:tag_list],
      permission_preset: p[:permission_preset],
      library: SiteSettings.show_libraries ? Library.find_param(p[:library]) : Library.default
    }
    @model = Model.new(common_attributes) # dummy model object
    if @model.valid?(multi_model ? :multi_upload : :single_upload)
      # Create model if there's just one
      single_model = create_model!(common_attributes) unless multi_model
      # Add files
      p[:file]&.values&.each do
        # If single_model is nil, this will create a model for each file
        # otherwise they get added to the passed model
        add_upload_to_model(
          tus_upload: it,
          model: single_model,
          attributes: common_attributes,
          auto_extract: multi_model || (num_files == 1 && is_archive?(it))
        )
      end
      respond_to do |format|
        format.html do
          if multi_model
            redirect_to models_path, notice: t(".success")
          else
            redirect_to single_model, notice: t(".success")
          end
        end
        format.manyfold_api_v0 {
          if multi_model
            head :accepted
          else
            head :created, location: model_path(single_model)
          end
        }
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
    @models = @filter.models(policy_scope(Model, policy_scope_class: ApplicationPolicy::UpdateScope)).includes(:collections, :creator)
    generate_available_tag_list
    page = params[:page] || 1
    # Double the normal page size for bulk editing
    @models = @models.page(page).per(helpers.pagination_settings["per_page"] * 2)
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
          redirect_to helpers.landing_page_path, notice: t(".success")
        else
          redirect_back_or_to helpers.landing_page_path, notice: t(".success")
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
    allowed = params.permit(
      :creator_id,
      :new_library_id,
      :organize,
      :license,
      :sensitive,
      collection_ids: [],
      add_tags: [],
      remove_tags: []
    )
    allowed[:collections] = CollectionPolicy::UpdateScope.new(current_user, Collection).resolve.where(public_id: allowed.delete(:collection_ids))
    allowed.compact_blank
  end

  def model_params
    if is_api_request?
      raise ActionController::BadRequest unless params[:json]
      ManyfoldApi::V0::ModelDeserializer.new(object: params[:json], user: current_user, record: @model).deserialize
    else
      Form::ModelDeserializer.new(params: params, user: current_user, record: @model).deserialize
    end
  end

  def upload_params
    if is_api_request?
      raise ActionController::BadRequest unless params[:json]
      ManyfoldApi::V0::UploadedModelDeserializer.new(object: params[:json], user: current_user).deserialize
    else
      Form::UploadedModelDeserializer.new(params: params, user: current_user).deserialize
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
    @default_creator = @creators.first if @creators.one?
    @collections = policy_scope(Collection, policy_scope_class: ApplicationPolicy::UpdateScope).local.order("LOWER(collections.name) ASC")
  end

  def set_returnable
    flash[:return_after_new] = request.fullpath.split("?")[0]
    @new_collection = Collection.find_param(params[:new_collection]) if params[:new_collection]
    @new_creator = Creator.find_param(params[:new_creator]) if params[:new_creator]
    if @model
      @model.collections << @new_collection unless @new_collection.nil? || @new_collection.in?(@model.collections)
      @model.creator = @new_creator if @new_creator
    end
  end

  def create_model!(attributes, name: nil)
    model = Model.create(attributes.merge({name: name, path: SecureRandom.uuid}.compact))
    Model.suppressing_turbo_broadcasts { model.organize! } if model
    model
  end

  def add_upload_to_model(tus_upload:, model: nil, attributes: {}, auto_extract: false)
    # Create a model for this file if we've not been given one
    model ||= create_model!(
      attributes,
      name: File.basename(tus_upload[:name], ".*").careful_titleize
    )
    # Add file to model
    AddUploadedFileToModelJob.perform_later(model.id, tus_upload.to_h.symbolize_keys, auto_extract: auto_extract) if model.persisted?
  end

  def is_archive?(tus_upload)
    MediaType.archive_extensions.include? File.extname(tus_upload[:name]).delete(".").downcase
  end
end
