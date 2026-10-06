# frozen_string_literal: true

class Components::FileFormatList < Components::Base
  def before_template
  end

  def view_template
    h2 { t(".title") }
    p { t(".description") }
    table class: "table table-striped" do
      [:model, :slicer, :image, :video, :archive, :document].each do |category|
        tr do
          th { category }
        end
        tr do
          th { t(".name") }
          FileHandlers.environments.each do |environment|
            th { t("file_handlers.environments.#{environment}") }
          end
        end
        MediaType::CATEGORIES[category].map do |type|
          tr do
            td { t("media_types.#{type}") }
            FileHandlers.environments.map do |environment|
              handlers = FileHandlers.handlers_for(environment: environment, mime_type: type)
              td do
                if handlers.empty?
                  span { "❌" }
                elsif environment.in?([:client])
                  span { "✅" }
                  whitespace
                  span { t("model_files.download.#{FileHandlers.handlers_for(environment: environment, mime_type: type).first.class_name.underscore}") }
                elsif environment.in?([:browser, :preview_frame])
                  span { "✅" }
                  whitespace
                  span { t("file_handlers.handlers.#{FileHandlers.handlers_for(environment: environment, mime_type: type).first.class_name.underscore}") }
                else
                  FileHandlers.handlers_for(environment: environment, mime_type: type).each do |it|
                    span { "✅" }
                    whitespace
                    span { t("file_handlers.handlers.#{it.class_name.underscore}") }
                    br
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
