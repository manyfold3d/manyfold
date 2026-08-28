# frozen_string_literal: true

class Components::PreviewFrame < Components::Base
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::Sanitize

  register_value_helper :policy_scope

  # lite: true for list/grid cards — never mounts WebGL.
  # eager: true for above-the-fold list cards (loading=eager, no content-visibility delay).
  def initialize(object:, lite: false, eager: false)
    @object = object
    @lite = lite
    @eager = eager
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

  def preview_container_class
    # Lite cards sit inside ModelCardPreview's reserved 4:3 slot — fill it absolutely
    # so the image cannot change card height when it loads.
    if @lite
      "absolute inset-0 overflow-hidden bg-secondary-100 dark:bg-secondary-800"
    else
      "relative block w-full aspect-[4/3] overflow-hidden bg-secondary-100 dark:bg-secondary-800"
    end
  end

  # INIT-006/SPEC-002: lite (browse/grid) and remote Image use contain so the
  # full preview is visible in the reserved 4:3 slot; non-lite keeps cover.
  def image_class
    fit = @lite ? "object-contain" : "object-cover"
    "absolute inset-0 w-full h-full #{fit}" + (needs_hiding? ? " sensitive" : "")
  end

  def render_local
    if @file.is_image?
      # Lite/grid cards: skip sync NFS exists_on_storage? — it adds ~200ms+ of
      # Synology round-trips per page and blocks TTFB. Broken paths 404 as <img>.
      if !@lite && !@file.exists_on_storage?
        return empty
      end

      div(class: preview_container_class) do
        opts = {
          class: image_class,
          alt: @file.name,
          loading: @eager ? "eager" : "lazy",
          decoding: "async",
          # Intrinsic size hint (4:3) so the browser can reserve space even without CSS.
          width: 480,
          height: 360
        }
        opts[:fetchpriority] = "high" if @eager
        opts[:sizes] = "(max-width: 640px) 50vw, 240px" if @lite
        # derivative:preview when present; controller falls back to original
        image_tag model_model_file_path(@file.model, @file, format: @file.extension, derivative: "preview"), **opts
      end
    elsif @file.is_renderable?
      if @lite
        renderable_placeholder
      else
        div(class: "#{preview_container_class} #{"sensitive" if needs_hiding?}") do
          Renderer file: @file
        end
      end
    else
      empty
    end
  end

  def renderable_placeholder
    div(class: "#{preview_container_class} flex flex-col items-center justify-center gap-2 text-secondary-400 #{"sensitive" if needs_hiding?}") do
      i(class: "bi bi-box-fill text-4xl opacity-60 relative z-10", "aria-hidden": "true")
      span(class: "text-xs font-medium uppercase tracking-wide relative z-10") { t("components.model_card.model_preview") }
    end
  end

  def render_remote
    actor = @object.is_a?(Federails::Actor) ? @object : @object.federails_actor
    preview_data = actor&.extensions&.dig("preview")
    case preview_data&.dig("type")
    when "Image"
      div(class: preview_container_class) do
        opts = {
          class: image_class,
          alt: sanitize(preview_data["summary"]),
          loading: @eager ? "eager" : "lazy",
          decoding: "async",
          width: 480,
          height: 360
        }
        opts[:fetchpriority] = "high" if @eager
        image_tag sanitize(preview_data["url"]), **opts
      end
    when "Document"
      div(class: "#{preview_container_class} #{"sensitive" if needs_hiding?}") do
        # Sanitize federated HTML — never wrap remote content in safe() raw.
        body = sanitize(preview_data["content"].to_s)
        iframe(
          scrolling: "no",
          srcdoc: safe([
            "<html><body style=\"margin: 0; padding: 0; aspect-ratio: 1\">",
            body,
            "</body></html>"
          ].join),
          title: sanitize(preview_data["summary"]),
          class: "absolute inset-0 w-full h-full object-cover border-0"
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
    classes = if @lite
      "absolute inset-0 flex items-center justify-center overflow-hidden bg-secondary-100 dark:bg-secondary-800 text-secondary-400"
    else
      "relative flex items-center justify-center w-full aspect-[4/3] overflow-hidden bg-secondary-100 dark:bg-secondary-800 text-secondary-400"
    end
    div(class: classes) do
      p(class: "text-sm") { t("components.model_card.no_preview") }
    end
  end
end
