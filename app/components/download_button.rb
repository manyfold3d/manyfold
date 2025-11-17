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
  end

  def view_template
    div class: "btn-group ml-auto mr-auto" do
      download_link html_class: "btn btn-primary"
      button type: "button",
        class: "btn btn-primary dropdown-toggle dropdown-toggle-split",
        data: {
          bs_toggle: "dropdown"
        },
        aria: {
          expanded: false,
          haspopup: "menu",
          controls: "download-menu"
        } do
        span(class: "visually-hidden") { t("components.download_button.menu_header") }
      end
      ul class: "dropdown-menu",
        id: "download-menu",
        aria: {
          role: "menu"
        } do
        DropdownHeader text: t("components.download_button.menu_header")
        if @has_supported_and_unsupported
          li(role: "menuitem") { download_link selection: "supported" }
          li(role: "menuitem") { download_link selection: "unsupported" }
          DropdownDivider
        end
        @extensions&.compact&.map do |type|
          li(role: "menuitem") { download_link file_type: type }
        end
      end
    end
  end

  def download_link(selection: nil, file_type: nil, html_class: "dropdown-item")
    downloader = ArchiveDownloadService.new(model: @model, selection: selection || file_type)
    link_options = {
      class: html_class,
      rel: "nofollow",
      download: (downloader.ready? ? "download" : nil)
    }
    if downloader.preparing?
      link_options.merge!(
        disabled: true,
        "aria-disabled": "true",
        tabindex: -1,
        class: html_class + " disabled"
      )
    end
    link_to model_path(@model, format: @format, selection: selection || file_type), link_options do
      if downloader.ready?
        Icon(icon: "cloud-download-fill", label: t("components.download_button.download.ready"))
      elsif downloader.preparing?
        Icon(icon: "hourglass-split", label: t("components.download_button.download.preparing"), effect: "icon-flip")
      else
        Icon(icon: "cloud-download", label: t("components.download_button.download.missing"))
      end
      whitespace
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
