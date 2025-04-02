class Scan::Model::ParseMetadataJob < ApplicationJob
  queue_as :scan
  unique :until_executed

  def perform(model_id)
    model = Model.find(model_id)
    return if model.remote?
    # Set tags and default files
    model.preview_file = model.model_files.min_by { |it| preview_priority(it) } unless model.preview_file
    if model.tags.empty?
      generate_tags_from_directory_name!(model) if SiteSettings.model_tags_tag_model_directory_name
      if SiteSettings.model_tags_auto_tag_new.present?
        model.tag_list << SiteSettings.model_tags_auto_tag_new
      end
    end
    if !model.creator_id && SiteSettings.parse_metadata_from_path
      parse_metadata_from_path(model)
    end
    model.save! # Problem check will run automatically after save
  end

  private

  def preview_priority(file)
    return 0 if file.is_image?
    return 1 if file.is_renderable?
    100
  end

  def generate_tags_from_directory_name!(model)
    tags = File.split(model.path).last.split(/[\W_+-]/).filter { |it| it.length > 1 }
    model.tag_list.add(remove_stop_words(tags))
  end

  def parse_metadata_from_path(model)
    return unless SiteSettings.model_path_template
    components = PathParserService.new(SiteSettings.model_path_template, model.path).call
    parse_tags(model, components[:tags])
    parse_creator(model, components[:creator])
    parse_collection(model, components[:collection])
    parse_name(model, components[:model_name])
  end

  def parse_creator(model, component)
    return unless component
    model.creator = find_or_create_from_path_component(Creator, component)
  end

  def parse_collection(model, component)
    return unless component
    model.collection = find_or_create_from_path_component(Collection, component)
  end

  def parse_name(model, component)
    return unless component
    model.name = to_human_name(component)
  end

  def parse_tags(model, component)
    return unless component
    model.tag_list.add(remove_stop_words(component).map { |tag| tag.titleize.downcase })
  end

  def remove_stop_words(words)
    return words if !SiteSettings.model_tags_filter_stop_words
    stopword_filter = Stopwords::Snowball::Filter.new(
      SiteSettings.model_tags_stop_words_locale,
      SiteSettings.model_tags_custom_stop_words
    )
    stopword_filter.filter(words)
  end

  def find_or_create_from_path_component(klass, path_component)
    klass.find_by(slug: path_component) ||
      klass.create_with(slug: path_component.parameterize).find_or_create_by(
        name: to_human_name(path_component)
      )
  end

  def to_human_name(str)
    str.humanize.tr("+", " ").careful_titleize
  end
end
