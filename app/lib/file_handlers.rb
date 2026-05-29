Rails.root.glob("lib/file_handlers/*.rb") { require it }

module FileHandlers
  ALL_HANDLERS = FileHandlers.constants.without(:Base, :Slic3rFamily).map { |it| FileHandlers.const_get("FileHandlers::#{it}") }.freeze

  def self.handlers_for(environment:, load_file:)
    ALL_HANDLERS # rubocop:disable Pundit/UsePolicyScope
      .select { |it| it.const_get(:ENVIRONMENTS).include? environment }
      .select { |it| it.can_load? Mime[load_file.mime_type] }
      .sort { |a, b| b&.priority <=> a&.priority }
  end
end
