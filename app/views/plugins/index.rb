# frozen_string_literal: true

module Views::Plugins
  class Index < Views::Base
    def initialize(plugins:)
      @plugins = plugins
    end

    def view_template
      h3 { t("views.plugins.index.title") }
      p { t("views.plugins.index.description_html", url: "https://manyfold.app/technology/plugins") }
      plugin_table
      remove_plugin
    end

    private

    def plugin_table
      return div(class: "alert alert-info") { t("views.plugins.index.no_plugins") } if @plugins.empty?

      table class: "table table-striped" do
        tr do
          th { t("views.plugins.index.plugin.active") }
          th { t("views.plugins.index.plugin.name") }
          th { t("views.plugins.index.plugin.version") }
          th { t("views.plugins.index.plugin.description") }
          th { t("views.plugins.index.plugin.authors") }
          th { t("views.plugins.index.plugin.links") }
        end
        @plugins.each do |plugin|
          tr do
            td { "✅" }
            td { plugin.name }
            td { plugin.version.to_s }
            td do
              details style: "width: 100%" do
                summary { plugin.summary }
                p { plugin.description }
              end
            end
            td { plugin.authors.join(", ") }
            td { a(href: plugin.homepage) { Icon(icon: "house-fill", label: t("views.plugins.index.homepage")) } }
          end
        end
      end
    end

    def remove_plugin
      hr
      h4 { t("views.plugins.index.remove") }s
      p { t("views.plugins.index.removal_instructions") }
    end
  end
end
