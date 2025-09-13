# frozen_string_literal: true

class Components::ModelCard < Components::Base
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::Sanitize
  include Phlex::Rails::Helpers::LinkTo

  register_output_helper :status_badges
  register_output_helper :server_indicator
  register_value_helper :policy

  def initialize(model:)
    @model = model
    @actor = @model.federails_actor
  end

  def view_template
    div class: "col mb-4" do
      div class: "card preview-card" do
        div(class: "card-header position-absolute w-100 top-0 z-3 bg-body-secondary text-secondary-emphasis opacity-75") { server_indicator @model } if @model.remote?
        PreviewFrame(object: @model)
        div(class: "card-body") { info_row }
        actions
      end
    end
  end

  private

  def title
    div class: "card-title" do
      a "data-editable-field": "model[name]", "data-editable-path": model_path(@model), contenteditable: "plaintext-only", "data-controller": "editable", "data-action": "focus->editable#onFocus blur->editable#onBlur" do
        @model.name
      end
      if @model.sensitive
        whitespace
        Icon(icon: "explicit", label: Model.human_attribute_name(:sensitive))
      end
      whitespace
      AccessIndicator(object: @model)
    end
  end

  def open_button
    if @actor && !@actor.local
      link_to @actor.profile_url, {class: "btn btn-primary btn-sm", "aria-label": translate("components.model_card.open_button.label", name: @actor.name)} do
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
      if @actor && !@actor.local
        if (creator = @actor.extensions["attributedTo"])
          li { creator target: creator["url"], name: creator["name"] }
        end
        if (collection = @actor.extensions["context"])
          li { collection target: collection["url"], name: collection["name"] }
        end
      else
        li { creator target: @model.creator, name: @model.creator.name } if @model.creator
        li { collection target: @model.collection, name: @model.collection.name } if @model.collection
      end
    end
  end

  def creator(target:, name:)
    Icon icon: "person", label: Creator.model_name.human
    whitespace
    link_to name, target, "aria-label": [Creator.model_name.human, name].join(": ")
  end

  def collection(target:, name:)
    Icon icon: "collection", label: Collection.model_name.human
    whitespace
    link_to name, target, "aria-label": [Collection.model_name.human, name].join(": ")
  end

  def caption
    if (summary = @model.try(:caption) || @actor.extensions&.dig("summary"))
      span class: "card-subtitle text-muted" do
        sanitize summary.split("</p>", 1).first
      end
    end
  end

  def info_row
    div class: "row" do
      div class: "col" do
        title
        caption
      end
      div class: "col-auto" do
        small do
          credits
        end
      end
    end
  end

  def actions
    div class: "card-footer" do
      div class: "row" do
        div class: "col" do
          open_button
          whitespace
          status_badges @model
        end
        div class: "col col-auto" do
          BurgerMenu do
            DropdownItem(icon: "pencil", label: t("components.model_card.edit_button.text"), path: edit_model_path(@model), aria_label: translate("components.model_card.edit_button.label", name: @model.name)) if policy(@model).edit?
            DropdownItem(icon: "trash", label: t("components.model_card.delete_button.text"), path: model_path(@model), method: :delete, aria_label: translate("components.model_card.delete_button.label", name: @model.name), confirm: translate("models.destroy.confirm")) if policy(@model).destroy?
            DropdownItem(icon: "flag", label: t("general.report", type: ""), path: new_model_report_path(@model)) if SiteSettings.multiuser_enabled?
          end
        end
      end
    end
  end
end
