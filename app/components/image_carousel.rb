class Components::ImageCarousel < Components::Base
  include Phlex::Rails::Helpers::FormWith

  register_value_helper :policy

  def initialize(images:)
    @images = images
  end

  def render?
    !@images.empty?
  end

  def view_template
    div id: "imageCarousel",
      class: "carousel slide mb-3",
      role: "group",
      data: {
        bs_ride: "carousel",
        controller: "carousel",
        action: "mouseenter->carousel#onEnter mouseleave->carousel#onLeave"
      },
      aria: {
        roledescription: "carousel"
      } do
      if @images.count > 1
        play_pause_control
      end
      div id: "imageCarouselInner",
        class: "carousel-inner",
        aria: {
          atomic: false,
          live: "off"
        } do
        @images.each_with_index do |image, index|
          div class: ((index == 0) ? "carousel-item active" : "carousel-item"),
            role: "group",
            aria: {
              roledescription: "slide",
              label: translate("components.image_carousel.slide_label", index: (index + 1), count: @images.count, name: image.name)
            } do
            img src: model_model_file_path(image.model, image, format: image.extension, derivative: "carousel"),
              alt: image.name,
              class: "d-block w-100 carousel"
            button_overlay(image)
          end
        end
      end
      if @images.count > 1
        slide_indicators
        next_prev_controls
      end
    end
  end

  private

  def play_pause_control
    button id: "rotationControl",
      class: "carousel-control-play btn btn-secondary m-2",
      data: {
        action: "click->carousel#onPauseButton"
      } do
      Icon icon: "pause", label: t("components.image_carousel.play_pause"), id: "rotationControlIcon"
    end
  end

  def slide_indicators
    div class: "carousel-indicators",
      role: "group",
      aria: {
        label: translate("components.image_carousel.select_slide")
      } do
      @images.each_with_index do |image, index|
        button type: "button",
          data: {
            bs_target: "#imageCarousel",
            bs_slide_to: index
          },
          class: ("active" if index == 0),
          aria: {
            label: translate("components.image_carousel.slide_label", index: (index + 1), count: @images.count, name: image.name),
            current: (index == 0),
            disabled: (index == 0)
          }
      end
    end
  end

  def next_prev_controls
    button class: "carousel-control-prev",
      type: "button",
      tabindex: -1,
      data: {
        bs_target: "#imageCarousel",
        bs_slide: "prev"
      } do
      span class: "carousel-control-prev-icon", aria: {hidden: true}
      span(class: "visually-hidden") { t("components.image_carousel.previous") }
    end
    button class: "carousel-control-next",
      type: "button",
      tabindex: -1,
      data: {
        bs_target: "#imageCarousel",
        bs_slide: "next"
      } do
      span class: "carousel-control-next-icon", aria: {hidden: true}
      span(class: "visually-hidden") { t("components.image_carousel.next") }
    end
  end

  def button_overlay(image)
    div class: "carousel-caption d-none d-md-block" do
      if image.model.preview_file != image && policy(image).edit?
        form_with model: image.model, class: "d-inline" do |form|
          form.hidden_field :preview_file_id, value: image.id
          form.button t("models.file.set_as_preview"), class: "btn btn-sm btn-outline-warning"
        end
      end
      if policy(image).destroy?
        a href: model_model_file_path(image.model, image),
          tabindex: 0,
          class: "btn btn-sm btn-outline-danger",
          data: {
            method: "delete",
            confirm: translate("model_files.destroy.confirm")
          } do
          Icon(icon: "trash", label: t("general.delete"))
        end
      end
    end
  end
end
