class ImagesController < ApplicationController
  before_action :get_library
  before_action :get_model
  before_action :get_image

  def show
    respond_to do |format|
      format.png { send_file File.join(@library.path, @model.path, @image.filename) }
      format.jpeg { send_file File.join(@library.path, @model.path, @image.filename) }
    end
  end

  private

  def get_library
    @library = Library.find(params[:library_id])
  end

  def get_model
    @model = @library.models.find(params[:model_id])
  end

  def get_image
    @image = @model.images.find(params[:id])
    @title = @image.name
  end
end
