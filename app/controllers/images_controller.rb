# app/controllers/images_controller.rb
class ImagesController < ApplicationController
  def resize
    original_image_path = params[:original_image_path]

    image_service = ImageService.new
    resized_image_path = image_service.get_resized_image(original_image_path)

    send_file resized_image_path, type: "image/jpeg", disposition: "inline"
  end
end
