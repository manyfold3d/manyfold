class FileHandlers::Rouge < FileHandlers::Base
  ENVIRONMENTS = [:browser].freeze

  INPUT_TYPES = ::Rouge::Lexer.all.filter_map { |lexer| # rubocop:disable Pundit/UsePolicyScope
    (Mime::LOOKUP.keys & lexer.mimetypes).map { Mime::LOOKUP[it] }.uniq
  }.flatten.freeze

  def self.priority
    100
  end

  def self.component
    Components::Renderers::Rouge
  end
end
