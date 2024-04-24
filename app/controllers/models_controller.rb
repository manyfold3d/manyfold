require "fileutils"

class ModelsController < ApplicationController
  include ModelFilters
  before_action :get_model, except: [:bulk_edit, :bulk_update, :index]
  after_action :verify_policy_scoped, only: [:bulk_edit, :bulk_update]

  def index
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
    @models = @models.includes [:library, :model_files]

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
    files = files.select(&:is_3d_model?)
    @groups = helpers.group(files)
    render layout: "card_list_page"
  end

  def edit
    @creators = Creator.all
    @collections = Collection.all
    @model.links.build if @model.links.empty? # populate empty link
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
    @model = Model.includes(:model_files, :creator).find(params[:id])
    authorize @model
    @title = @model.name
  end
end
