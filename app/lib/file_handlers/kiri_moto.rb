class FileHandlers::KiriMoto < FileHandlers::Base
  # i18n-tasks-use t("file_handlers.handlers.kiri_moto")

  ENVIRONMENTS = [:slice].freeze

  INPUT_TYPES = [Mime[:stl]].freeze

  def self.component
    Components::Slicers::KiriMoto
  end
end
