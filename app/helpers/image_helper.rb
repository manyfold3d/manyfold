module ImageHelper
    module ImageCache
        def cached_resized_image_path(original_image_path)
          cache_key = "#{original_image_path}_preview"
          cache_path = Rails.root.join('tmp', 'image_cache', cache_key)
      
          if File.exist?(cache_path)
            cache_path
          else
            resized_image_path = resize_image(original_image_path)
            FileUtils.mkdir_p(File.dirname(cache_path))
            FileUtils.cp(resized_image_path, cache_path)
            resized_image_path
          end
        end
      end
  
    module ImageResizer
    require "image_processing/vips"
    
        def resize_image(image_path)
            processed = ImageProcessing::Vips
                        .source(image_path)
                        .resize_to_limit(300, 300)
                        .convert('webp')
                        .saver(strip: true)
                        .call
            processed.path
        end
    end
end