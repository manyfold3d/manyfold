class FileHandlers::KiriMoto < FileHandlers::Base
  # i18n-tasks-use t("file_handlers.handlers.kiri_moto")

  ENVIRONMENTS = [:edit].freeze

  INPUT_TYPES = Mime::EXTENSION_LOOKUP.slice("obj", "3mf", "stl").values.freeze

  def self.component
    Components::Slicers::KiriMoto
  end
end
