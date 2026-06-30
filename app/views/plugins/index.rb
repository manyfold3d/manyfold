# frozen_string_literal: true

module Views::Plugins
  class Index < Views::Base
    include Phlex::Rails::Helpers::FormTag
    include Phlex::Rails::Helpers::FileFieldTag
    include Phlex::Rails::Helpers::SubmitTag

    def initialize(plugins:)
      @plugins = plugins
    end

    def view_template
      h3 { t("views.plugins.index.title") }
      p { t("views.plugins.index.description_html", url: "https://manyfold.app/sysadmin/plugins") }
      plugin_table
      add_plugin
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

    def add_plugin
      hr
      h4 { t("views.plugins.index.install.title") }
      p { t("views.plugins.index.install.instructions") }
      if PluginManager.can_install_plugins?
        div(class: "alert alert-warning") { t("views.plugins.index.install.warning") }
        form_tag(settings_plugins_path, multipart: true) do |f|
          div class: "input-group" do
            f.file_field_tag "plugin_file", class: "form-control", accept: ".zip,application/zip"
            f.submit_tag translate("views.plugins.index.install.button"), class: "btn btn-secondary"
          end
        end
      else
        div(class: "alert alert-danger") { t("views.plugins.index.install.error_html", url: "https://manyfold.app/sysadmin/plugins") }
      end
    end

    def remove_plugin
      hr
      h4 { t("views.plugins.index.remove") }
      p { t("views.plugins.index.removal_instructions") }
    end
  end
end
