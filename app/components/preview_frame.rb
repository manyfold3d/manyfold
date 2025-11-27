# frozen_string_literal: true

class Components::PreviewFrame < Components::Base
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::Sanitize

  register_value_helper :policy_scope

  def initialize(object:)
    @object = object
  end

  def before_template
    return if remote?
    @file = @object.is_a?(Model) ? @object.preview_file : policy_scope(@object.models).first&.preview_file
  end

  def view_template
    if @file
      render_local
    elsif remote?
      render_remote
    else
      empty
    end
  end

  private

  def remote?
    @object.is_a?(Federails::Actor) ? !@object.local : @object.remote?
  end

  def render_local
    if @file.is_image?
      image model_model_file_path(@file.model, @file, format: @file.extension, derivative: "preview"), @file.name
    elsif @file.is_renderable?
      div class: "card-img-top #{"sensitive" if needs_hiding?}" do
        Renderer file: @file
      end
    else
      empty
    end
  end

  def render_remote
    actor = @object.is_a?(Federails::Actor) ? @object : @object.federails_actor
    preview_data = actor&.extensions&.dig("preview")
    case preview_data&.dig("type")
    when "Image"
      image sanitize(preview_data["url"]), sanitize(preview_data["summary"])
    when "Document"
      div class: "card-img-top #{"sensitive" if needs_hiding?}" do
        iframe(
          scrolling: "no",
          srcdoc: safe([
            "<html><body style=\"margin: 0; padding: 0; aspect-ratio: 1\">",
            preview_data["content"],
            "</body></html>"
          ].join),
          title: sanitize(preview_data["summary"])
        )
      end
    else
      empty
    end
  end

  def needs_hiding?
    return false unless current_user.nil? || current_user.sensitive_content_handling.present?
    case @object.class
    when Model
      @object.sensitive
    when Collection
      @file.model.sensitive
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
    image_tag url, class: "card-img-top image-preview #{"sensitive" if needs_hiding?}", alt: alt
  end
end
