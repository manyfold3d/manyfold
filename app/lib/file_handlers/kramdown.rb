class FileHandlers::Kramdown < FileHandlers::Base
  # i18n-tasks-use t("file_handlers.handlers.kramdown")

  ENVIRONMENTS = [:browser].freeze
  INPUT_TYPES = Mime::EXTENSION_LOOKUP.slice("md").values.freeze

  def self.priority
    200
  end

  def self.component
    Components::Renderers::Kramdown
  end
end
