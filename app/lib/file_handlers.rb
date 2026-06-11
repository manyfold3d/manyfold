Rails.root.glob("lib/file_handlers/*.rb") { require it }

module FileHandlers
  ALL_HANDLERS = FileHandlers.constants.without(:Base, :Slic3rFamily).map { |it| FileHandlers.const_get("FileHandlers::#{it}") }.freeze

  def self.handlers_for(environment:, mime_type:)
    Rails.cache.fetch("FileHandlers_handlers_for_#{environment}_#{mime_type}", expires_in: 1.hour) do
      Rails.logger.debug { "CACHE MISS for FileHandlers_handlers_for_#{environment}_#{mime_type}" }
      ALL_HANDLERS # rubocop:disable Pundit/UsePolicyScope
        .select { |it| it.const_get(:ENVIRONMENTS).include? environment }
        .select { |it| it.can_load? mime_type }
        .sort { |a, b| b&.priority <=> a&.priority }
    end
  end
end
