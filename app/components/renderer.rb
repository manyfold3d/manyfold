# frozen_string_literal: true

class Components::Renderer < Components::Base
  include Phlex::Rails::Helpers::JavascriptPath
  include Phlex::Rails::Helpers::NumberToHumanSize

  def initialize(file:)
    @file = file
  end

  def render?
    @file&.is_renderable?
  end

  def before_template
    @settings = current_user&.renderer_settings || SiteSettings::UserDefaults::RENDERER
  end

  def view_template
    div class: "position-relative", data: {turbo_permanent: true} do
      img src: model_model_file_path(@file.model, @file, format: @file.extension, derivative: :render), class: "card-img-top image-preview", alt: @file.name if @file.has_render?
      canvas id: "preview-file-#{@file.to_param}",
        class: "object-preview position-relative",
        tabindex: "0",
        data: {
          controller: "renderer",
          preview_url: model_model_file_by_filename_path(@file.model, @file.filename),
          worker_url: javascript_path("offscreen_renderer.js"),
          format: @file.extension,
          y_up: @file.y_up.to_s,
          grid_size_x: @settings["grid_width"],
          grid_size_z: @settings["grid_depth"],
          show_grid: @settings["show_grid"].to_s,
          enable_pan_zoom: @settings["enable_pan_zoom"].to_s,
          background_colour: @settings["background_colour"],
          object_colour: @settings["object_colour"],
          render_style: @settings["render_style"],
          auto_load: ((@file.size || 9_999_999.megabytes) < (@settings["auto_load_max_size"] || 9_999_999).megabytes) ? "true" : "false"
        }
      div class: "p-0 btn btn-sm btn-secondary load-progress object-preview-progress position-absolute mt-3 start-50 translate-middle-x translate-top", role: "presentation" do
        div class: "progress-bar bg-info progress-bar-animated progress-bar-striped", role: "progressbar", style: "width: 0%; height: 100%",
          aria_label: "Loading progress", aria_valuenow: "0", aria_valuemin: "0", aria_valuemax: "100"
        span class: "progress-label position-absolute top-50 start-50 translate-middle", role: "button" do
          Icon icon: "box"
          whitespace
          span { t("renderer.load") }
          whitespace
          span { "(#{number_to_human_size @file.size, precision: 2})" }
        end
      end
    end
  end
end
