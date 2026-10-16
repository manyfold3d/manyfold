module Components::Renderers
  class Kramdown < Components::Renderers::Base
    include Phlex::Rails::Helpers::Sanitize

    def self.supports?(file)
      FileHandlers::Kramdown.can_load? file&.mime_type
    end

    def before_template
      @content = @file.attachment.read.force_encoding(Encoding::UTF_8).encode("UTF-8", invalid: :replace)
    end

    def view_template
      div class: "card" do
        article class: "card-body" do
          sanitize(
            ::Kramdown::Document.new(
              @content,
              header_offset: 2,
              input: "GFM"
            ).to_html
          )
        end
      end
    end
  end
end
