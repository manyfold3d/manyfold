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
    @cover = @object.try(:cover)
    return if @cover
    @file = @object if @object.is_a?(ModelFile)
    @file = @object.preview_file if @object.is_a?(Model)
    @file = collection_preview_file if @object.is_a?(Collection)
  end

  def view_template
    if @file || @cover
      render_local
    elsif remote?
      render_remote
    else
      empty
    end
  end

  private

  def collection_preview_file
    if @object.preview_model && ModelPolicy.new(current_user, @object.preview_model)
      @object.preview_model&.preview_file
    else
      policy_scope(@object.models).first&.preview_file
    end
  end

  def remote?
    @object.is_a?(Federails::Actor) ? !@object.local : @object.try(:remote?)
  end

  def render_local
    if @cover
      url = cover_collection_path(@object)
      div class: "card-img-top card-img-top-background", style: "background-image: url(#{url})"
      image_tag url, class: "card-img-top image-preview #{"sensitive" if needs_hiding?}", alt: @object.name
    elsif @file.is_image?
      url = model_model_file_path(@file.model, @file, format: @file.extension, derivative: "preview")
      div class: "card-img-top card-img-top-background", style: "background-image: url(#{url})"
      image_tag url, class: "card-img-top image-preview #{"sensitive" if needs_hiding?}", alt: @file.name
    elsif (handler = FileHandlers::Base.handlers_for(environment: :preview_frame, load_file: @file)&.first)
      div class: "card-img-top #{"sensitive" if needs_hiding?}" do
        render handler.component.new(file: @file, derivative: "preview")
      end
    elsif @file.has_render?
      url = model_model_file_path(@file.model, @file, format: @file.extension, derivative: "render")
      div class: "card-img-top card-img-top-background", style: "background-image: url(#{url})"
      image_tag url, class: "card-img-top image-preview #{"sensitive" if needs_hiding?}", alt: @file.name
    elsif @file
      file_icon
    else
      empty
    end
  end

  def render_remote
    actor = @object.is_a?(Federails::Actor) ? @object : @object.federails_actor
    preview_data = actor&.extensions&.dig("preview")
    case preview_data&.dig("type")
    when "Image"
      url = sanitize(preview_data["url"])
      div class: "card-img-top card-img-top-background", style: "background-image: url(#{url})"
      image_tag url, class: "card-img-top image-preview #{"sensitive" if needs_hiding?}", alt: sanitize(preview_data["summary"])
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
    case @object.class.name
    when "Model"
      @object.sensitive
    when "Collection"
      @file&.model&.sensitive
    else
      false
    end
  end

  def file_icon
    div class: "card-img-top", style: "aspect-ratio: 1" do
      svg height: "100%", width: "100%", viewBox: "0 0 100 100" do |svg|
        svg.path stroke: "black", stroke_linecap: "round", stroke_width: "0.5", fill: "white", d: "
            M60,15
            h-30
            q-5,0 -5,5
            v65
            q0,5 5,5
            h40
            q5,0 5,-5
            v-55
            L60,15
          "
        svg.path stroke: "black", stroke_linecap: "round", stroke_width: "0.5", fill: "transparent", d: "
            M60,15
            v10
            q0,5 5,5
            h10
          "
        svg.text x: "50%", y: "80%", fill: "black", dominant_baseline: "middle", text_anchor: "middle", style: "font-size: 8px" do
          @file.extension&.upcase
        end
      end
    end
  end

  def empty
    div class: "preview-empty" do
      p { t("components.model_card.no_preview") }
    end
  end
end
