class FileHandlers::PlaintextForm < FileHandlers::Base
  # i18n-tasks-use t("file_handlers.handlers.plaintext_form")

  ENVIRONMENTS = [:edit].freeze

  INPUT_TYPES = Mime::EXTENSION_LOOKUP.slice("html", "js", "txt", "md").values.freeze

  def self.component
    Components::Editors::PlaintextForm
  end
end
