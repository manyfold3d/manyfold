class Components::Renderers::Rouge < Components::Renderers::Base
  def self.supports?(file)
    FileHandlers::Rouge.can_load? file&.mime_type
  end

  def before_template
    @formatter = ::Rouge::Formatters::HTMLLineTable.new(::Rouge::Formatters::HTML.new)
    @lexer = ::Rouge::Lexer.all.find { @file.mime_type.in? it.mimetypes } # rubocop:disable Pundit/UsePolicyScope
  end

  def view_template
    style do
      style { raw(safe(::Rouge::Themes::ThankfulEyes.render(scope: ".rouge"))) } # rubocop:disable Rails/OutputSafety
    end
    div class: "rouge" do
      raw(safe(@formatter.format(@lexer.lex(@file.attachment.read)))) # rubocop:disable Rails/OutputSafety
    end
  end
end
