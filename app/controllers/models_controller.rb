require "fileutils"

class ModelsController < ApplicationController
  include ModelFilters
  before_action :get_model, except: [:bulk_edit, :bulk_update, :index, :new, :create]
  after_action :verify_policy_scoped, only: [:bulk_edit, :bulk_update]

  def index
    # Work out policies for showing buttons up front
    @can_show = policy(Model).show?
    @can_destroy = policy(Model).destroy?
    @can_edit = policy(Model).edit?

    process_filters_init

    # Ordering
    @models = case session["order"]
    when "recent"
      @models.order(created_at: :desc)
    else
      @models.order(name: :asc)
    end

    if current_user.pagination_settings["models"]
      page = params[:page] || 1
      @models = @models.page(page).per(current_user.pagination_settings["per_page"])
    end

    process_filters_tags_fetchall
    process_filters
    process_filters_tags_highlight

    # Load extra data
    @models = @models.includes [:library, :model_files, :preview_file, :creator, :collection]

    render layout: "card_list_page"
  end

  def show
    files = @model.model_files
    @images = files.select(&:is_image?)
    @images.unshift(@model.preview_file) if @images.delete(@model.preview_file)
    if current_user.file_list_settings["hide_presupported_versions"]
      hidden_ids = files.select(:presupported_version_id).where.not(presupported_version_id: nil)
      files = files.where.not(id: hidden_ids)
    end
    files = files.includes(:presupported_version, :problems)
    files = files.select(&:is_3d_model?)
    @groups = helpers.group(files)
    render layout: "card_list_page"
  end

  def new
    authorize :model
  end

  def edit
    @creators = Creator.all
    @collections = Collection.all
    @model.links.build if @model.links.empty? # populate empty link
  end

  def create
    authorize :model
    library = Library.find(params[:library])
    uploads = begin
      JSON.parse(params[:uploads])[0]["successful"]
    rescue
      []
    end

    save_files(library,
      uploads.map { |x| x["response"]["body"] })

    redirect_to libraries_path, notice: t(".success")
  end

  def update
    if @model.update(model_params)
      redirect_to [@model.library, @model], notice: t(".success")
    else
      edit # Load creators and collections
      flash.now[:alert] = t(".failure")
      render :edit
    end
  end

  def merge
    if params[:target] && (target = (@model.parents.find { |x| x.id == params[:target].to_i }))
      @model.merge_into! target
      Scan::CheckModelIntegrityJob.perform_later(target.id)
      redirect_to [target.library, target], notice: t(".success")
    elsif params[:all] && @model.contains_other_models?
      @model.contained_models.each do |child|
        child.merge_into! @model
      end
      Scan::CheckModelIntegrityJob.perform_later(@model.id)
      redirect_to [@model.library, @model], notice: t(".success")
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
    redirect_to [@model.library, @model], notice: t(".success")
  end

  def bulk_edit
    authorize Model
    @creators = policy_scope(Creator)
    @collections = policy_scope(Collection)
    @models = policy_scope(Model)
    process_filters
  end

  def bulk_update
    authorize Model
    hash = bulk_update_params
    hash[:library_id] = hash.delete(:new_library_id) if hash[:new_library_id]

    add_tags = Set.new(hash.delete(:add_tags))
    remove_tags = Set.new(hash.delete(:remove_tags))
    ids = params[:models].select { |k, v| v == "1" }.keys
    policy_scope(Model).find(ids).each do |model|
      if model&.update(hash)
        existing_tags = Set.new(model.tag_list)
        model.tag_list = existing_tags + add_tags - remove_tags
        model.save
      end
    end
    redirect_back_or_to edit_models_path(@filters), notice: t(".success")
  end

  def destroy
    @model.delete_from_disk_and_destroy
    if request.referer && (URI.parse(request.referer).path == library_model_path(@model.library, @model))
      # If we're coming from the model page itself, we can't go back there
      redirect_to library_path(@model.library), notice: t(".success")
    else
      redirect_back_or_to library_path(@model.library), notice: t(".success")
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
    )
  end

  def get_model
    @model = Model.includes(:model_files, :creator, :preview_file, :library, :tags, :taggings, :links).find(params[:id])
    authorize @model
    @title = @model.name
  end

  def save_files(library, files)
    files.each do |x|
      attacher = Shrine::Attacher.new
      attacher.attach_cached(x)
      datafile = attacher.file
      # Check file extension as proxy for MIME type - to be improved in other work soon
      next unless helpers.uploadable_file_extensions.include? File.extname(datafile.original_filename).delete(".").downcase
      # Then open it up
      file_name_with_zip = datafile.original_filename
      file_name = File.basename(file_name_with_zip, File.extname(file_name_with_zip))
      dest_folder_name = File.join(library.path, SecureRandom.uuid)
      if !Dir.exist?(dest_folder_name)
        unzip(dest_folder_name, datafile)
      end
      # Rename destination folder atomically
      File.rename(dest_folder_name, File.join(library.path, file_name))
      # Queue up model creation for new folder
      Scan::CreateModelJob.perform_later(library.id, file_name, include_all_subfolders: true)
      # Discard cached file
      attacher.destroy
    end
  end

  def unzip(dest_folder_name, datafile)
    datafile.open do |file|
      Archive::Reader.open_fd(file.fileno) do |reader|
        Dir.mkdir(dest_folder_name)
        Dir.chdir(dest_folder_name) do
          reader.each_entry do |entry|
            next if entry.size > SiteSettings.max_file_extract_size
            reader.extract(entry, Archive::EXTRACT_SECURE)
          end
        end
      end
    end

    # Checks the directory just created and if it contains only one directory,
    # moves the contents of that directory up a level, then deletes the empty directory.
    pn = Pathname.new(dest_folder_name)
    if pn.children.length == 1 && pn.children[0].directory?
      dup_dir = Pathname.new(pn.children[0])

      dup_dir.children.each do |child|
        fixed_path = Pathname.new(pn.to_s + "/" + child.basename.to_s)
        File.rename(child.to_s, fixed_path.to_s)
      end

      Dir.delete(dup_dir.to_s)
    end
  end
end
