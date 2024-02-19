class ImageService
    include ImageHelper::ImageCache
    include ImageHelper::ImageResizer
  
    def get_resized_image(original_image_path)
      cached_resized_image_path(original_image_path)
    end
  end
  