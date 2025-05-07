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
      link_to model_path(@model, format: @format), class: "btn btn-lg btn-primary", download: "download" do # i18n-tasks-use t('components.download_button.label')
        icon("cloud-download", "")
        whitespace
        span { t("components.download_button.label") }
      end
      button(type: "button",
        class: "btn btn-lg btn-primary dropdown-toggle dropdown-toggle-split",
        "data-bs-toggle": "dropdown",
        "aria-expanded": "false") do
        span class: "visually-hidden" do
          t("components.download_button.menu_header") # i18n-tasks-use t('components.download_button.menu_header')
        end
      end
      ul class: "dropdown-menu" do
        li class: "dropdown-header" do
          t("components.download_button.menu_header") # i18n-tasks-use t('components.download_button.menu_header')
        end
        if @has_supported_and_unsupported
          li do
            link_to model_path(@model, format: @format, selection: "supported"), class: "dropdown-item", download: "download" do # i18n-tasks-use t('components.download_button.supported')
              t("components.download_button.supported")
            end
          end
          li do
            link_to model_path(@model, format: @format, selection: "unsupported"), class: "dropdown-item", download: "download" do # i18n-tasks-use t('components.download_button.unsupported')
              t("components.download_button.unsupported")
            end
          end
          li { hr class: "dropdown-divider" }
        end
        @extensions&.compact&.map do |type|
          li do
            link_to model_path(@model, format: @format, selection: type), class: "dropdown-item", download: "download" do # i18n-tasks-use t('components.download_button.file_type')
              t("components.download_button.file_type", type: type.upcase)
            end
          end
        end
      end
    end
  end
end
