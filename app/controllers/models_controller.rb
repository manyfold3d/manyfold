require "fileutils"

class ModelsController < ApplicationController
  include ModelListable
  include Permittable

  before_action :get_model, except: [:bulk_edit, :bulk_update, :index, :new, :create]
  before_action :get_creators_and_collections, only: [:new, :edit, :bulk_edit]
  before_action :set_returnable, only: [:bulk_edit, :edit, :new]
  before_action :clear_returnable, only: [:bulk_update, :update, :create]

  after_action :verify_policy_scoped, only: [:bulk_edit, :bulk_update]

  def index
    @models = filtered_models @filters
    prepare_model_list
    render layout: "card_list_page"
  end

  def show
    respond_to do |format|
      format.html do
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
        @extensions = @model.file_extensions
        @has_supported_and_unsupported = @model.has_supported_and_unsupported?
        @download_format = :zip
        render layout: "card_list_page"
      end
      format.zip do
        tmpdir = LibraryUploader.find_storage(:cache).directory
        filename = [
          @model.slug,
          params[:selection]
        ].compact.join("-") + ".zip"
        tmpfile = File.join(tmpdir, "#{@model.updated_at.to_time.to_i}-#{@model.id}-#{params[:selection]}.zip")
        unless File.exist?(tmpfile)
          files = file_list(@model, params[:selection])
          write_archive(tmpfile, files)
        end
        send_file(tmpfile, filename: filename, type: :zip, disposition: :attachment)
        # We will rely on Shrine to clean up the temp file
      end
    end
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
      :sensitive,
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
      :sensitive,
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

  def file_list(model, selection)
    case selection
    when nil
      model.model_files
    when "supported"
      model.model_files.where(presupported: true)
    when "unsupported"
      model.model_files.where(presupported: false)
    else
      model.model_files.select { |f| f.extension == selection }
    end
  end

  def write_archive(filename, files)
    Archive.write_open_filename(filename, Archive::COMPRESSION_COMPRESS, Archive::FORMAT_ZIP) do |archive|
      files.each do |file|
        archive.new_entry do |entry|
          entry.pathname = file.filename
          entry.size = file.size
          entry.filetype = Archive::Entry::FILE
          archive.write_header entry
          archive.write_data file.attachment.read
        end
      end
    end
  end
end
