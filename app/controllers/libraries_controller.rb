class LibrariesController < ApplicationController
  before_action :get_library, except: [:index, :new, :create, :scan_all]
  skip_after_action :verify_policy_scoped, only: [:index]

  def index
    if Library.count === 0
      redirect_to new_library_path
    else
      redirect_to models_path
    end
  end

  def show
    redirect_to models_path(library: @library.id)
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
      Scan::DetectFilesystemChangesJob.perform_later(@library.id)
      redirect_to @library, notice: t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :new
    end
  end

  def update
    @library.update(library_params)
    uptags = library_params[:tag_regex]&.reject(&:empty?)
    @library.tag_regex = uptags
    if @library.save
      redirect_to models_path, notice: t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :edit
    end
  end

  def scan
    Scan::DetectFilesystemChangesJob.perform_later(@library.id)
    redirect_back_or_to @library, notice: t(".success")
  end

  def scan_all
    authorize Library
    if params[:type] === "check"
      Scan::CheckAllJob.perform_later
    else
      Library.find_each do |library|
        Scan::DetectFilesystemChangesJob.perform_later(library.id)
      end
    end
    redirect_back_or_to models_path, notice: t(".success")
  end

  def destroy
    @library.destroy
    redirect_to libraries_path, notice: t(".success")
  end

  private

  def library_params
    params.require(:library).permit(:path, :name, :notes, :caption, :icon, {tag_regex: []})
  end

  def get_library
    @library = Library.find(params[:id])
    authorize @library
    @title = @library.name
  end
end
