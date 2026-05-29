class FileHandlers::IframeTag < FileHandlers::Base
  ENVIRONMENTS = [:browser].freeze
  INPUT_TYPES = Mime::EXTENSION_LOOKUP.slice("pdf", "html", "text", "md").values.freeze

  def self.priority
    200
  end

  def self.component
    Components::Renderers::IframeTag
  end
end
