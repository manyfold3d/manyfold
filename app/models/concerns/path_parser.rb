module PathParser
  extend ActiveSupport::Concern

  def generate_tags_from_directory_name!
    tags = File.split(path).last.split(/[\W_+-]/).filter { |it| it.length > 1 }
    tag_list.add(remove_stop_words(tags))
  end

  def parse_metadata_from_path
    return unless SiteSettings.model_path_template
    components = PathParserService.new(SiteSettings.model_path_template, path).call
    parse_tags(components[:tags])
    parse_creator(components[:creator])
    parse_collection(components[:collection])
    parse_name(components[:model_name])
  end

  private

  def parse_creator(component)
    return unless component
    self.creator = find_or_create_from_path_component(Creator, component)
  end

  def parse_collection(component)
    return unless component
    self.collection = find_or_create_from_path_component(Collection, component)
  end

  def parse_name(component)
    return unless component
    self.name = to_human_name(component)
  end

  def parse_tags(component)
    return unless component
    tag_list.add(remove_stop_words(component).map { |tag| tag.titleize.downcase })
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
