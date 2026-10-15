module Components::Renderers
  class Plaintext < Components::Renderers::Base
    include Phlex::Rails::Helpers::Sanitize

    def self.supports?(file)
      FileHandlers::Plaintext.can_load? file&.mime_type
    end

    def before_template
      @content = @file.attachment.read.force_encoding(Encoding::UTF_8).encode("UTF-8", invalid: :replace)
    end

    def view_template
      article class: "card" do
        pre class: "card-body" do
          sanitize(@content)
        end
      end
    end
  end
end
