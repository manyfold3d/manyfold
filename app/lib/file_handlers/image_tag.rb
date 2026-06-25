class FileHandlers::ImageTag < FileHandlers::Base
  ENVIRONMENTS = [:browser, :preview_frame].freeze
  INPUT_TYPES = MediaType.image_types

  def self.component
    Components::Renderers::ImageTag
  end
end
