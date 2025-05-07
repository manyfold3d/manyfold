# frozen_string_literal: true

class Components::DownloadButton < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  def initialize(model:, format: :zip)
    @model = model
    @format = format
  end

  def before_template
    @extensions = @model.file_extensions.excluding("json")
    @has_supported_and_unsupported = @model.has_supported_and_unsupported?
    @downloaders = {
      nil => ArchiveDownloadService.new(model: @model, selection: nil)
    }
  end

  def view_template
    div class: "btn-group ml-auto mr-auto" do
      download_link html_class: "btn btn-lg btn-primary", icon_name: "cloud-download"
      button(type: "button",
        class: "btn btn-lg btn-primary dropdown-toggle dropdown-toggle-split",
        "data-bs-toggle": "dropdown",
        "aria-expanded": "false") do
        span(class: "visually-hidden") { t("components.download_button.menu_header") }
      end
      ul class: "dropdown-menu" do
        li(class: "dropdown-header") { t("components.download_button.menu_header") }
        if @has_supported_and_unsupported
          li { download_link selection: "supported" }
          li { download_link selection: "unsupported" }
          li { hr class: "dropdown-divider" }
        end
        @extensions&.compact&.map do |type|
          li { download_link file_type: type }
        end
      end
    end
  end

  def download_link(selection: nil, file_type: nil, html_class: "dropdown-item", icon_name: nil)
    link_to model_path(@model, format: @format, selection: selection || file_type), class: html_class, download: "download" do
      if icon_name
        icon(icon_name, "")
        whitespace
      end
      span do
        if file_type
          t("components.download_button.file_type", type: file_type.upcase)
        elsif selection
          # i18n-tasks-use t('components.download_button.supported')
          # i18n-tasks-use t('components.download_button.unsupported')
          t("components.download_button.%{selection}" % {selection: selection})
        else
          t("components.download_button.label")
        end
      end
    end
  end
end
