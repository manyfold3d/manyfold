module FileHandlers
  # i18n-tasks-use t("file_handlers.environments.browser")
  # i18n-tasks-use t("file_handlers.environments.client")
  # i18n-tasks-use t("file_handlers.environments.preview_frame")
  # i18n-tasks-use t("file_handlers.environments.convert")
  # i18n-tasks-use t("file_handlers.environments.thumbnail")

  ALL_HANDLERS = []

  def self.handlers_for(environment:, mime_type:)
    Rails.cache.fetch("FileHandlers_handlers_for_#{environment}_#{mime_type}", expires_in: 1.hour) do
      Rails.logger.debug { "CACHE MISS for FileHandlers_handlers_for_#{environment}_#{mime_type}" }
      ALL_HANDLERS # rubocop:disable Pundit/UsePolicyScope
        .select { it.const_get(:ENVIRONMENTS).include? environment }
        .select { it.can_load? mime_type }
        .sort { |a, b| b&.priority <=> a&.priority }
    end
  end

  def self.environments
    ALL_HANDLERS.map { it.const_get(:ENVIRONMENTS) }.flatten.uniq
  end
end
