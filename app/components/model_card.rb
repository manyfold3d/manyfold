# frozen_string_literal: true

class Components::ModelCard < Components::Base
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::Sanitize
  include Phlex::Rails::Helpers::LinkTo

  register_output_helper :status_badges
  register_output_helper :server_indicator

  def initialize(model:, can_edit: false, can_destroy: false)
    @model = model
    @can_destroy = can_destroy
    @can_edit = can_edit
  end

  def view_template
    div class: "col mb-4" do
      div class: "card preview-card" do
        preview_frame
        div class: "card-body" do
          info_row
          actions_row
        end
      end
    end
  end

  private

  def needs_hiding?(thing)
    thing.sensitive && (current_user.nil? || current_user.sensitive_content_handling.present?)
  end

  def preview_frame
    if (file = @model.preview_file)
      if file.is_image?
        div class: "card-img-top card-img-top-background", style: "background-image: url(#{model_model_file_path(@model, file, format: file.extension)})"
        image_tag model_model_file_path(@model, file, format: file.extension), class: "card-img-top image-preview #{"sensitive" if needs_hiding?(@model)}", alt: file.name
      elsif file.is_renderable?
        div class: "card-img-top #{"sensitive" if needs_hiding?(@model)}" do
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
  end

  def title
    div class: "card-title" do
      a "data-editable-field": "model[name]", "data-editable-path": model_path(@model), contenteditable: "plaintext-only", "data-controller": "editable", "data-action": "focus->editable#onFocus blur->editable#onBlur" do
        @model.name
      end
      Icon(icon: "explicit", label: Model.human_attribute_name(:sensitive)) if @model.sensitive
      br
      server_indicator @model
    end
  end

  def edit_menu_item
    return unless @can_edit
    li do
      link_to edit_model_path(@model), class: "dropdown-item", "aria-label": translate("components.model_card.edit_button.label", name: @model.name) do
        Icon(icon: "pencil-fill", label: t("components.model_card.edit_button.text"))
        whitespace
        span { t("components.model_card.edit_button.text") }
      end
    end
  end

  def destroy_menu_item
    return unless @can_destroy
    li do
      link_to model_path(@model), {method: :delete, class: "dropdown-item", data: {confirm: translate("models.destroy.confirm")}} do
        Icon(icon: "trash", label: t("components.model_card.delete_button.label"))
        whitespace
        span { t("components.model_card.delete_button.text") }
      end
    end
  end

  def report_menu_item
    return unless SiteSettings.multiuser_enabled?
    li do
      link_to new_model_report_path(@model), class: "dropdown-item" do
        Icon(icon: "flag", label: t("general.report", type: ""))
        whitespace
        span { t("general.report", type: "") }
      end
    end
  end

  def open_button
    if @model.remote?
      link_to @model.federails_actor.profile_url, {class: "btn btn-primary btn-sm", "aria-label": translate("components.model_card.open_button.label", name: @model.name)} do
        span { "⁂" }
        whitespace
        span { t("components.model_card.open_button.text") }
      end
    else
      link_to t("components.model_card.open_button.text"), @model, {class: "btn btn-primary btn-sm", "aria-label": translate("components.model_card.open_button.label", name: @model.name)}
    end
  end

  def credits
    ul class: "list-unstyled" do
      if @model.creator
        li do
          Icon icon: "person", label: Creator.model_name.human
          link_to @model.creator.name, @model.creator, "aria-label": [Creator.model_name.human, @model.creator.name].join(": ")
        end
      end
      if @model.collection
        li do
          Icon icon: "collection", label: @model.collection.model_name.human
          link_to @model.collection.name, @model.collection, "aria-label": [@model.collection.model_name.human, @model.collection.name].join(": ")
        end
      end
    end
  end

  def caption
    if @model.caption
      p class: "card-text" do
        sanitize @model.caption
      end
    end
  end

  def menu
    div class: "float-end" do
      div class: "btn-group" do
        a href: "#", role: "button", "data-bs-toggle": "dropdown", "aria-expanded": "false" do
          Icon icon: "three-dots-vertical", label: t("general.menu")
        end
        ul class: "dropdown-menu dropdown-menu-end" do
          edit_menu_item
          destroy_menu_item
          report_menu_item
        end
      end
    end
  end

  def info_row
    div class: "row" do
      div class: "col" do
        title
      end
      div class: "col-auto" do
        small do
          credits
          caption
        end
      end
    end
  end

  def actions_row
    div class: "row" do
      div class: "col" do
        open_button
        whitespace
        status_badges(@model)
        menu
      end
    end
  end
end
