# frozen_string_literal: true

class Components::PreviewFrame < Components::Base
  include Phlex::Rails::Helpers::ImageTag

  def initialize(object:)
    @object = object
    @file = @object.preview_file
  end

  def view_template
    if @file
      local
    elsif @object.remote?
      remote
    else
      empty
    end
  end

  private

  def local
    if @file.is_image?
      image model_model_file_path(@file.model, @file, format: @file.extension, derivative: "preview"), @file.name
    elsif @file.is_renderable?
      div class: "card-img-top #{"sensitive" if needs_hiding?(@object)}" do
        Renderer file: @file
      end
    else
      empty
    end
  end

  def remote
    preview_data = @object.federails_actor&.extensions&.dig("preview")
    case preview_data&.dig("type")
    when "Image"
      image preview_data["url"], preview_data["summary"]
    when "Document"
      div class: "card-img-top #{"sensitive" if needs_hiding?(@object)}" do
        iframe(
          scrolling: "no",
          srcdoc: safe([
            "<html><body style=\"margin: 0; padding: 0; aspect-ratio: 1\">",
            preview_data["content"],
            "</body></html>"
          ].join),
          title: preview_data["summary"]
        )
      end
    else
      empty
    end
  end

  def needs_hiding?(thing)
    return false unless current_user.nil? || current_user.sensitive_content_handling.present?
    case thing.class
    when Model
      thing.sensitive
    when Collection
      thing.preview_file.sensitive
    else
      false
    end
  end

  def empty
    div class: "preview-empty" do
      p { t("components.model_card.no_preview") }
    end
  end

  def image(url, alt)
    div class: "card-img-top card-img-top-background", style: "background-image: url(#{url})"
    image_tag url, class: "card-img-top image-preview #{"sensitive" if needs_hiding?(@object)}", alt: alt
  end
end
