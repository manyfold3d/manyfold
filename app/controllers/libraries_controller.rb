class LibrariesController < ApplicationController
  before_action :get_library, except: [:index, :new, :create]

  def index
    if Library.count === 0
      redirect_to new_library_path
    else
      redirect_to Library.first
    end
  end

  def show
    @models =
      if current_user.pagination_settings
        page = params[:page] || 1
        @library.models.includes(:tags, :preview_file, :creator).paginate(page: page, per_page: current_user.pagination_settings["per_page"])
      else
        @library.models.includes(:tags, :preview_file, :creator)
      end

    @tags = @library.models.includes(:tags).map(&:tags).flatten.uniq.sort_by(&:name)

    @scanning = Delayed::Job.count > 0
    # Filter by tag?
    if params[:tag]
      @tag = ActsAsTaggableOn::Tag.find_by_name(params[:tag])
      @models = @models.tagged_with(@tag) if @tag
    end
  end

  def new
    @library = Library.new
    @title = "New Library"
  end

  def create
    @library = Library.create(library_params)
    if @library.valid?
      LibraryScanJob.perform_later(@library)
      redirect_to @library
    else
      render :new
    end
  end

  def update
    LibraryScanJob.perform_later(@library)
    redirect_to @library
  end

  def destroy
    @library.destroy
    redirect_to libraries_path
  end

  private

  def library_params
    params.require(:library).permit(:path)
  end

  def get_library
    @library = Library.find(params[:id])
    @title = @library.name
  end
end
