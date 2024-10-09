require "fileutils"

class ModelsController < ApplicationController
  include Filterable
  include TagListable
  include Permittable

  before_action :get_model, except: [:bulk_edit, :bulk_update, :index, :new, :create]
  before_action :get_creators_and_collections, only: [:new, :edit, :bulk_edit]
  before_action :set_returnable, only: [:bulk_edit, :edit, :new]
  before_action :clear_returnable, only: [:bulk_update, :update, :create]

  after_action :verify_policy_scoped, only: [:bulk_edit, :bulk_update]

  def index
    # Work out policies for showing buttons up front
    @can_destroy = policy(Model).destroy?
    @can_edit = policy(Model).edit?

    @models = filtered_models @filters

    # Ordering
    @models = case session["order"]
    when "recent"
      @models.order(created_at: :desc)
    else
      @models.order(name_lower: :asc)
    end

    @tags, @unrelated_tag_count = generate_tag_list(@models, @filter_tags)
    @tags, @kv_tags = split_key_value_tags(@tags)

    if helpers.pagination_settings["models"]
      page = params[:page] || 1
      @models = @models.page(page).per(helpers.pagination_settings["per_page"])
    end

    # Load extra data
    @models = @models.includes [:library, :model_files, :preview_file, :creator, :collection]

    render layout: "card_list_page"
  end

  def show
    files = @model.model_files
    @images = files.select(&:is_image?)
    @images.unshift(@model.preview_file) if @images.delete(@model.preview_file)
    if helpers.file_list_settings["hide_presupported_versions"]
      hidden_ids = files.select(:presupported_version_id).where.not(presupported_version_id: nil)
      files = files.where.not(id: hidden_ids)
    end
    files = files.includes(:presupported_version, :problems)
    files = files.reject(&:is_image?)
    @groups = helpers.group(files)
    render layout: "card_list_page"
  end

  def new
    authorize :model
  end

  def edit
    @model.links.build if @model.links.empty? # populate empty link
    @model.caber_relations.build if @model.caber_relations.empty?
  end

  def create
    authorize :model
    library = Library.find_param(params[:library])
    uploads = begin
      JSON.parse(params[:uploads])[0]["successful"]
    rescue
      []
    end

    uploads.each do |upload|
      ProcessUploadedFileJob.perform_later(
        library.id,
        upload["response"]["body"],
        owner: current_user,
        creator_id: params[:creator_id],
        collection_id: params[:collection_id],
        license: params[:license],
        tags: params[:add_tags]
      )
    end

    redirect_to libraries_path, notice: t(".success")
  end

  def update
    hash = model_params
    organize = hash.delete(:organize) == "true"
    if @model.update(hash)
      OrganizeModelJob.perform_later(@model.id) if organize
      redirect_to @model, notice: t(".success")
    else
      redirect_back_or_to edit_model_path(@model), alert: t(".failure")
    end
  end

  def merge
    if params[:target] && (target = (@model.parents.find { |x| x.public_id == params[:target] }))
      @model.merge_into! target
      redirect_to target, notice: t(".success")
    elsif params[:all] && @model.contains_other_models?
      @model.contained_models.each do |child|
        child.merge_into! @model
      end
      redirect_to @model, notice: t(".success")
    else
      head :bad_request
    end
  end

  def scan
    # Clear digests for files so that we force a full geometry rescan
    @model.model_files.update_all(digest: nil) # rubocop:disable Rails/SkipsModelValidations
    # Start the scans
    Scan::CheckModelJob.perform_later(@model.id)
    # Back to the model page
    redirect_to @model, notice: t(".success")
  end

  def bulk_edit
    authorize Model
    @models = filtered_models @filters
    @remove_tags, _unused = generate_tag_list(@models)
    @add_tags = ActsAsTaggableOn::Tag.where.not(id: @remove_tags.pluck(:id))
    # Apply tag filters in-place
    @filter_in_place = true
  end

  def bulk_update
    authorize Model
    hash = bulk_update_params
    hash[:library_id] = hash.delete(:new_library_id) if hash[:new_library_id]
    organize = hash.delete(:organize) == "1"
    add_tags = Set.new(hash.delete(:add_tags))
    remove_tags = Set.new(hash.delete(:remove_tags))
    ids = params[:models].select { |k, v| v == "1" }.keys
    policy_scope(Model).where(public_id: ids).find_each do |model|
      if model&.update(hash)
        existing_tags = Set.new(model.tag_list)
        model.tag_list = existing_tags + add_tags - remove_tags
        model.save
      end
      OrganizeModelJob.perform_later(model.id) if organize
    end
    redirect_back_or_to edit_models_path(@filters), notice: t(".success")
  end

  def destroy
    @model.delete_from_disk_and_destroy
    if request.referer && (URI.parse(request.referer).path == model_path(@model))
      # If we're coming from the model page itself, we can't go back there
      redirect_to root_path, notice: t(".success")
    else
      redirect_back_or_to root_path, notice: t(".success")
    end
  end

  private

  def bulk_update_params
    params.permit(
      :creator_id,
      :collection_id,
      :new_library_id,
      :organize,
      :license,
      add_tags: [],
      remove_tags: []
    ).compact_blank
  end

  def model_params
    params.require(:model).permit(
      :preview_file_id,
      :creator_id,
      :library_id,
      :name,
      :caption,
      :notes,
      :license,
      :collection_id,
      :q,
      :library,
      :creator,
      :tag,
      :organize,
      :missingtag,
      tag_list: [],
      links_attributes: [:id, :url, :_destroy]
    ).deep_merge(caber_relations_params(type: :model))
  end

  def get_model
    @model = Model.includes(:model_files, :creator, :preview_file, :library, :tags, :taggings, :links, :caber_relations).find_param(params[:id])
    authorize @model
    @title = @model.name
  end

  def get_creators_and_collections
    @creators = policy_scope(Creator).order("LOWER(name) ASC")
    @collections = policy_scope(Collection).order("LOWER(name) ASC")
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
end
