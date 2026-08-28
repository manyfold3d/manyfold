# frozen_string_literal: true

class Components::ModelCardPreview < Components::Base
  include Phlex::Rails::Helpers::LinkTo

  register_output_helper :server_indicator
  register_value_helper :policy

  def initialize(model:, editable:, actor: nil, eager_preview: false, gallery: false)
    @model = model
    @editable = editable
    @actor = actor || model.federails_actor
    @eager_preview = eager_preview
    @gallery = gallery
  end

  def view_template
    # Outer aspect box owns the reserved height; fill link/button must be absolute
    # so nested PreviewFrame cannot collapse the slot before the image loads.
    div(class: "relative w-full aspect-[4/3] overflow-hidden bg-secondary-100 dark:bg-secondary-800") do
      selection_bubble if @editable
      ModelListActions(model: @model) if current_user
      if @actor && !@actor.local
        div(class: "absolute inset-0") do
          PreviewFrame(object: @model, lite: true, eager: @eager_preview)
        end
      elsif @gallery && gallery_eligible?
        button type: "button",
          class: "absolute inset-0 block w-full h-full p-0 m-0 border-0 bg-transparent cursor-zoom-in focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-primary-500",
          data: {
            action: "click->model-gallery#open",
            model_gallery_model_url_param: model_path(@model),
            model_gallery_gallery_url_param: gallery_model_path(@model),
            model_gallery_model_name_param: @model.name
          },
          aria: {haspopup: "dialog", label: translate("components.model_gallery.preview_label", name: @model.name)} do
          PreviewFrame(object: @model, lite: true, eager: @eager_preview)
        end
      else
        link_to @model, class: "absolute inset-0 block no-underline", data: {turbo_frame: "_top"}, aria: {label: translate("components.model_card.open_button.label", name: @model.name)} do
          PreviewFrame(object: @model, lite: true, eager: @eager_preview)
        end
      end
    end
  end

  private

  def gallery_eligible?
    file = @model.preview_file
    file.present? && file.is_image?
  end

  def selection_bubble
    button type: "button",
      class: "model-card-selection-bubble absolute top-2 left-2 z-20 w-5 h-5 rounded-full border-2 border-white dark:border-secondary-300 bg-white/40 dark:bg-secondary-500/70 flex items-center justify-center focus-visible:ring-2 focus-visible:ring-primary-500 focus-visible:ring-offset-2 transition-opacity",
      data: {model_id: @model.public_id, action: "click->model-list-selection#toggle", model_list_selection_target: "bubble"},
      aria: {label: t("models.list.selection.select"), pressed: "false"} do
      i(class: "bi bi-check-lg model-card-selection-check text-white text-xs opacity-0 transition-opacity pointer-events-none font-bold", "aria-hidden": "true")
    end
  end
end
