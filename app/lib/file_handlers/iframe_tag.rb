class FileHandlers::IframeTag < FileHandlers::Base
  # i18n-tasks-use t("file_handlers.handlers.iframe_tag")

  ENVIRONMENTS = [:browser].freeze
  INPUT_TYPES = Mime::EXTENSION_LOOKUP.slice("pdf", "html", "text", "md").values.freeze

  def self.priority
    200
  end

  def self.component
    Components::Renderers::IframeTag
  end
end
