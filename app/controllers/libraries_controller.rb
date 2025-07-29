class LibrariesController < ApplicationController
  before_action :get_library, except: [:index, :new, :create]
  skip_after_action :verify_policy_scoped, only: [:index]

  def index
    redirect_to new_library_path and return if Library.count === 0 # rubocop:disable Pundit/UsePolicyScope
    render layout: "settings"
  end

  def show
    redirect_to models_path(library: @library)
  end

  def new
    authorize Library
    @library = Library.new
    @title = t("libraries.general.new")
  end

  def edit
  end

  def create
    authorize Library
    @library = Library.create(library_params)
    @library.tag_regex = params[:tag_regex]
    if @library.valid?
      @library.detect_filesystem_changes_later
      @library.make_default if SiteSettings.default_library.nil?
      redirect_to @library, notice: t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @library.update(library_params)
    uptags = library_params[:tag_regex]&.reject(&:empty?)
    @library.tag_regex = uptags
    if @library.save
      @library.make_default if params.dig("library", "default") == "1"
      redirect_to models_path, notice: t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    begin
      @library.destroy
      Library.first&.make_default if @library.default?
    rescue Shrine::Error # Not ideal, but file after_commit callbacks explode if the library has gone
      nil
    end
    redirect_to settings_libraries_path, notice: t(".success")
  end

  private

  def library_params
    params.expect(library: [
      :path, :create_path_if_not_on_disk, :name, :notes, :caption, :icon, {tag_regex: []}, :storage_service,
      :s3_endpoint, :s3_bucket, :s3_region, :s3_access_key_id, :s3_secret_access_key, :s3_path_style
    ])
  end

  def get_library
    @library = Library.find_param(params[:id])
    authorize @library
    @title = @library.name
  end
end
