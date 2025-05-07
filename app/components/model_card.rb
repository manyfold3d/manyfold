# frozen_string_literal: true

class Components::ModelCard < Components::Base
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::Sanitize
  include Phlex::Rails::Helpers::LinkTo

  def initialize(model:, can_edit: false, can_destroy: false)
    @model = model
    @can_destroy = can_destroy
    @can_edit = can_edit
  end

  def view_template
    div class: "col mb-4" do
      div class: "card preview-card" do
        if (file = @model.preview_file)
          if file.is_image?
            div class: "card-img-top card-img-top-background", style: "background-image: url(#{model_model_file_path(@model, file, format: file.extension)})"
            image_tag model_model_file_path(@model, file, format: file.extension), class: "card-img-top image-preview #{"sensitive" if helpers.needs_hiding?(@model)}", alt: file.name
          elsif file.is_renderable?
            div class: "card-img-top #{"sensitive" if helpers.needs_hiding?(@model)}" do
              render partial("object_preview", model: @model, file: file)
            end
          end
        elsif @model.remote?
          div class: "preview-empty" do
            p { t("components.model_card.no_remote_preview") }
          end
        else
          div class: "preview-empty" do
            p { t("components.model_card.no_preview") }
          end
        end
        div class: "card-body" do
          div class: "row " do
            div class: "col" do
              div class: "card-title" do
                a "data-field": "model[name]", "data-path": model_path(@model), contenteditable: true do
                  @model.name
                end
                helpers.icon("explicit", Model.human_attribute_name(:sensitive)) if @model.sensitive
                br
                helpers.server_indicator @model
              end
            end
            div class: "col-auto" do
              small do
                ul class: "list-unstyled" do
                  if @model.creator
                    li do
                      helpers.icon "person", Creator.model_name.human
                      link_to @model.creator.name, @model.creator, "aria-label": [Creator.model_name.human, @model.creator.name].join(": ")
                    end
                  end
                  if @model.collection
                    li do
                      helpers.icon "collection", @model.collection.model_name.human
                      link_to @model.collection.name, @model.collection, "aria-label": [@model.collection.model_name.human, @model.collection.name].join(": ")
                    end
                  end
                end
                if @model.caption
                  p class: "card-text" do
                    sanitize @model.caption
                  end
                end
              end
            end
          end
          div class: "row" do
            div class: "col" do
              if @model.remote?
                link_to @model.federails_actor.profile_url, {class: "btn btn-primary btn-sm", "aria-label": translate("components.model_card.open_button.label", name: @model.name)} do
                  span { "⁂" }
                  whitespace
                  span { t("components.model_card.open_button.text") }
                end
              else
                link_to t("components.model_card.open_button.text"), @model, {class: "btn btn-primary btn-sm", "aria-label": translate("components.model_card.open_button.label", name: @model.name)}
              end
              helpers.status_badges(@model)
              div class: "float-end" do
                div class: "btn-group" do
                  a href: "#", role: "button", "data-bs-toggle": "dropdown", "aria-expanded": "false" do
                    helpers.icon "three-dots-vertical", t("general.menu")
                  end
                  ul class: "dropdown-menu dropdown-menu-end" do
                    if @can_edit
                      li do
                        link_to edit_model_path(@model), class: "dropdown-item", "aria-label": translate("components.model_card.edit_button.label", name: @model.name) do
                          helpers.icon("pencil-fill", t("components.model_card.edit_button.text"))
                          whitespace
                          span { t("components.model_card.edit_button.text") }
                        end
                      end
                    end
                    if @can_destroy
                      li do
                        link_to model_path(@model), {method: :delete, class: "dropdown-item", data: {confirm: translate("models.destroy.confirm")}} do
                          helpers.icon("trash", t("components.model_card.delete_button.label"))
                          whitespace
                          span { t("components.model_card.delete_button.text") }
                        end
                      end
                    end
                    if SiteSettings.multiuser_enabled?
                      li do
                        link_to new_model_report_path(@model), class: "dropdown-item" do
                          helpers.icon("flag", t("general.report", type: ""))
                          whitespace
                          span { t("general.report", type: "") }
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
