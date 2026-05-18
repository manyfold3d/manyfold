class FileHandlers::Rouge < FileHandlers::Base
  class << self
    def environments
      [:browser]
    end

    def priority
      100
    end

    def component
      Components::Renderers::Rouge
    end

    def input_types
      ::Rouge::Lexer.all.filter_map do |lexer| # rubocop:disable Pundit/UsePolicyScope
        (Mime::LOOKUP.keys & lexer.mimetypes).map { |it| Mime::LOOKUP[it] }.uniq
      end.flatten
    end
  end
end
