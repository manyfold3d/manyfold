class LibrariesController < ApplicationController
  before_action :get_library, except: [:index, :new, :create, :scan_all]

  def index
    if Library.count === 0
      redirect_to new_library_path
    else
      redirect_to models_path
    end
  end

  def show
    redirect_to models_path(library: params[:id])
  end

  def new
    @library = Library.new
    @title = "New Library"
  end

  def edit
  end

  def create
    @library = Library.create(library_params)
    @library.tag_regex = params[:tag_regex]
    if @library.valid?
      LibraryScanJob.perform_later(@library)
      redirect_to @library
    else
      render :new
    end
  end

  def update
    @library.update(library_params)
    uptags = library_params[:tag_regex].reject(&:empty?)
    @library.tag_regex = uptags
    @library.save
    redirect_to models_path
  end

  def scan
    LibraryScanJob.perform_later(@library)
    redirect_to @library
  end

  def scan_all
    Library.all.each do |library|
      LibraryScanJob.perform_later(library)
    end
    redirect_to models_path
  end

  def destroy
    @library.destroy
    redirect_to libraries_path
  end

  private

  def library_params
    params.require(:library).permit(:path, :name, :notes, :caption, {tag_regex: []})
  end

  def get_library
    @library = Library.find(params[:id])
    @title = @library.name
  end
end
