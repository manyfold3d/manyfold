module PathParser
  extend ActiveSupport::Concern

  def autogenerate_tags_from_path!
    tags = []

    # Auto-tag based on model directory name:
    if SiteSettings.model_tags_tag_model_directory_name
      tags = File.split(path).last.split(/[\W_+-]/).filter { |x| x.length > 1 }
    end

    unless tags.empty?
      tag_list.add(remove_stop_words(tags))
      save!
    end
  end

  def autogenerate_creator_from_prefix_template!
    if SiteSettings.model_path_prefix_template
      components = extract_path_components
      if components[:tags] && !components[:tags].empty?
        tag_list.add(remove_stop_words(components[:tags]))
      end
      self.creator = Creator.find_or_create_by(name: components[:creator]) if components[:creator]
      collection_list.add(components[:collection]) if components[:collection]
      save!
    end
  end
end

def path_parse_pattern
  Regexp.new("^/?.*?" +
    SiteSettings.model_path_prefix_template.gsub(/{.+?}/) { |token|
      case token
      when "{tags}"
        "(?<tags>[[:print:]]*)"
      when "{creator}"
        "(?<creator>[[:print:]&&[^/]]*?)"
      when "{collection}"
        "(?<collection>[[:print:]&&[^/]]*?)"
      when "{modelName}"
        "(?<model_name>[[:print:]&&[^/]]*?)"
      when "{modelId}"
        "(?<model_id>#[[:digit:]]+)?"
      else
        "[[:print:]&&[^/]]*"
      end
    } + "$")
end

def extract_path_components
  components = path.match(path_parse_pattern)&.named_captures&.symbolize_keys
  return {} if components.nil?
  components.merge({
    tags: components[:tags]&.split("/")&.compact_blank,
    model_id: nil # discard ID, never gonna use it in parsing
  }).compact
end

def remove_stop_words(words)
  return words if !SiteSettings.model_tags_filter_stop_words
  stopword_filter = Stopwords::Snowball::Filter.new(
    SiteSettings.model_tags_stop_words_locale,
    SiteSettings.model_tags_custom_stop_words
  )
  stopword_filter.filter(words)
end
