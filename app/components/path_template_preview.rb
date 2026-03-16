class Components::PathTemplatePreview < Components::Base
  include Phlex::Rails::Helpers::TurboFrameTag

  def initialize(library:)
    @library = library
  end

  def before_template
    @paths = @library.sample(3).map { |it| [it, PathParserService.new(@library.path_template, it).call] }
  end

  def view_template
    turbo_frame_tag "parse-preview" do
      if @library.parse_metadata_from_path
        p { t("components.path_template_preview.description") }
        table class: "table table-striped table-sm" do
          tr do
            th { t("components.path_template_preview.path") }
            th { Creator.model_name.human }
            th { Collection.model_name.human }
            th { ActsAsTaggableOn::Tag.model_name.human(count: 100) }
            th { Model.model_name.human }
          end
          @paths.map do |path, parsed|
            tr do
              td { path }
              td { find_or_new_from_path_component(Creator, parsed[:creator])&.name || "❌" }
              td { find_or_new_from_path_component(Collection, parsed[:collection])&.name || "❌" }
              td {
                parsed[:tags]&.map do |it|
                  Tag tag: ActsAsTaggableOn::Tag.new(name: it), link: false
                  whitespace
                end || "❌"
              }
              td { to_human_name(parsed[:model_name]) || "❌" }
            end
          end
        end
      end
    end
  end

  private

  def find_or_new_from_path_component(klass, path_component)
    return unless path_component
    klass.find_by(slug: path_component) ||
      klass.find_by(
        name: to_human_name(path_component)
      ) ||
      klass.new(name: to_human_name(path_component))
  end

  def to_human_name(str)
    str&.humanize&.tr("+", " ")&.careful_titleize
  end
end
