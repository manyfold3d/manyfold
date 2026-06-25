class FileHandlers::VideoTag < FileHandlers::Base
  ENVIRONMENTS = [:browser, :preview_frame].freeze
  INPUT_TYPES = MediaType.video_types.freeze

  def self.component
    Components::Renderers::VideoTag
  end
end
