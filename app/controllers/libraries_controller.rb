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
    @models = @library.models
    @tags = @models.map(&:tags).flatten.uniq.sort_by(&:name)
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
    LibraryScanJob.perform_later(@library)
    redirect_to @library
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
