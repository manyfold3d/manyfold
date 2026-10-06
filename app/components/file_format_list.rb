# frozen_string_literal: true

class Components::FileFormatList < Components::Base
  def before_template
    @categories = [:model, :slicer, :image, :video, :archive, :document]
    @environments = [:server, :preview_frame, :browser, :client]
  end

  def view_template
    h2 { t("components.file_format_list.title") }
    p { t("components.file_format_list.description") }
    @categories.map { category_section(it) }
  end

  def category_section(category)
    media_types = MediaType::CATEGORIES[category].map { {name: t("media_types.%{type}" % {type: it}), media_type: it} }
    h3 { t("media_types.categories.%{category}" % {category: category}) }
    table class: "table table-striped table-sm table-hover table-fixed" do
      thead do
        tr do
          th { t("components.file_format_list.file_type") }
          th(class: "d-none d-md-table-cell") { t("components.file_format_list.extensions") }
          @environments.each do |environment|
            th { t("file_handlers.environments.%{environment}" % {environment: environment}) }
          end
        end
      end
      tbody do
        Naturally.sort_by(media_types) { it[:name].downcase }.map do
          media_type_row(name: it[:name], media_type: it[:media_type])
        end
      end
    end
  end

  def media_type_row(name:, media_type:)
    extensions = [media_type, MediaType::EXTENSIONS[media_type]].flatten.uniq.compact
    extensions.reject! { it.starts_with?("three") || it.starts_with?("seven") } # Ugh
    tr do
      td { name }
      td(class: "d-none d-md-table-cell") do
        extensions.map { "*.#{it}" }.join(", ")
      end
      @environments.map do |environment|
        handlers = FileHandlers.handlers_for(environment: environment, mime_type: media_type)
        td do
          if handlers.empty?
            none
          elsif environment.in?([:client])
            all(environment: environment, media_type: media_type)
          else
            preferred(environment: environment, media_type: media_type)
          end
        end
      end
    end
  end

  def none
    span { "❌" }
  end

  def all(environment:, media_type:)
    translations = FileHandlers.handlers_for(environment: environment, mime_type: media_type).map { t("model_files.download.%{name}" % {name: it.class_name.underscore}) }
    Naturally.sort(translations).each do |item|
      span { "✅" }
      whitespace
      span(class: "d-none d-md-inline") do
        span { item }
        br
      end
    end
  end

  def preferred(environment:, media_type:)
    best = FileHandlers.handlers_for(environment: environment, mime_type: media_type).first
    span { "✅" }
    whitespace
    span(class: "d-none d-xl-inline") { t("file_handlers.handlers.%{name}" % {name: best.class_name.underscore}) }
  end
end
