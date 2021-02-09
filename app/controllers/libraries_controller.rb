class LibrariesController < ApplicationController
  def index
    if Library.count === 0
      redirect_to new_library_path
    else
      redirect_to Library.first
    end
  end

  def show
    @library = Library.find(params[:id])
  end

  def new
    @library = Library.new
  end

  def create
    @library = Library.create(library_params)
    LibraryScanJob.perform_later(@library)
    redirect_to @library
  end

  def update
    @library = Library.find(params[:id])
    LibraryScanJob.perform_later(@library)
    redirect_to @library
  end

  private

  def library_params
    params.require(:library).permit(:path)
  end
end
