class Scan::Model::ParseMetadataJob < ApplicationJob
  queue_as :scan
  unique :until_executed

  README_FILES = [
    "readme",
    "readme.md",
    "readme.txt"
  ]

  def perform(model_id)
    model = Model.find(model_id)
    return if model.remote?
    # Loads metadata in order of priority; README, datapackage, path template,
    # Some things are high-priority if already set
    options = {
      creator: model.creator,
      collections: model.collections,
      preview_file: model.preview_file,
      notes: model.notes,
      tag_list: model.tag_list
    }.compact_blank
    # Load information from READMEs
    options = combine_options options, attributes_from_readme(model.model_files.find_by(filename_lower: README_FILES))
    # Load from datapackage
    options = combine_options options, attributes_from_datapackage(model)
    # Set path template attributes
    options = combine_options options, attributes_from_path_template(model.library, model.path)
    # Add additional tags
    tag_list = tags_from_directory_name(model.path) + tags_from_path_template(model.library, model.path)
    options[:tag_list] = options[:tag_list] + remove_stop_words(tag_list.uniq)
    # Set preview file
    options = combine_options options, identify_preview_file(model)
    # Store new metadata
    model.update!(options.compact_blank!)
  end

  private

  def identify_preview_file(model)
    {
      preview_file: Naturally.sort_by(model.valid_preview_files, :filename).min_by { |it| preview_priority(it) }
    }
  end

  def preview_priority(file)
    return 0 if file.is_image?
    return 1 if Components::Renderers::Three.supports?(file)
    100
  end

  def tags_from_directory_name(path)
    return [] unless SiteSettings.model_tags_tag_model_directory_name
    File.split(path).last.split(/[\W_+-]/).filter { |it| it.length > 1 }
  end

  def attributes_from_path_template(library, path)
    return {} unless library.parse_metadata_from_path && library.path_template
    components = PathParserService.new(library.path_template, path).call
    {
      creator: find_or_create_from_path_component(Creator, components[:creator]),
      collections: Array(find_or_create_from_path_component(Collection, components[:collections])),
      name: to_human_name(components[:model_name])
    }.compact_blank
  end

  ASCII_ART_THINGIVERSE_README = /(?<url>https?:\/\/www\.thingiverse\.com\/thing:[0-9]+)\n(?<title>.*) by (?<creator>.*) is licensed under the (?<license_name>.*) license\.\n(?<license_url>https?:\/\/.*)\n\n# Summary\n\n(?<summary>.*)/
  SIMPLE_THINGIVERSE_README = /(?<title>.*) by (?<creator>.*) on Thingiverse: (?<url>https?:\/\/www\.thingiverse\.com\/thing:[0-9]+)/

  def attributes_from_readme(file)
    return {} if file.nil?
    content = file.attachment.read.force_encoding(Encoding::UTF_8)
    case content
    when SIMPLE_THINGIVERSE_README
      attributes_from_simple_thingiverse_readme(content)
    when ASCII_ART_THINGIVERSE_README
      attributes_from_ascii_art_thingiverse_readme(content)
    else
      attributes_from_generic_readme(content)
    end
  end

  def attributes_from_generic_readme(content)
    {
      notes: content
    }
  end

  def attributes_from_ascii_art_thingiverse_readme(content)
    content = filter_thingiverse_text(content)
    matches = content.match ASCII_ART_THINGIVERSE_README
    {
      name: matches[:title],
      notes: matches[:summary],
      links_attributes: [
        {url: matches[:url]}
      ],
      creator: find_or_create_from_path_component(Creator, matches[:creator]),
      license: license_id_from_url(matches[:license_url])
    }.compact
  end

  def attributes_from_simple_thingiverse_readme(content)
    content = filter_thingiverse_text(content)
    matches = content.match SIMPLE_THINGIVERSE_README
    {
      name: matches[:title],
      links_attributes: [
        {url: matches[:url]}
      ],
      creator: find_or_create_from_path_component(Creator, matches[:creator])
    }
  end

  def attributes_from_datapackage(model)
    if (datapackage_content = model.datapackage_content)
      data = DataPackage::ModelDeserializer.new(datapackage_content).deserialize
      # match creator
      creator_data = data.delete(:creator)
      if creator_data
        data[:creator] = creator_data[:id] ? Creator.find(creator_data.delete(:id)) :
          find_or_create_from_path_component(Creator, creator_data[:name])
        data[:creator].update(creator_data)
      end
      # match collections
      collections_data = data.delete(:collections) || []
      data[:collections] = []
      collections_data.each do |collection_data|
        collection = collection_data[:id] ? Collection.find(collection_data.delete(:id)) :
          find_or_create_from_path_component(Collection, collection_data[:name])
        collection.update(collection_data)
        data[:collections] << collection
      end
      # match preview file
      data[:preview_file] = model.model_files.find_by(filename: data[:preview_file])
      # Set file data
      data.delete(:model_files)&.each do |file|
        model.model_files.find_by(filename: file.delete(:filename))&.update(file)
      end
      # Merge in to main lists
      tag_list.concat data.delete(:tag_list) if data.key?(:tag_list)
      # Done
      data.compact_blank
    else
      {}
    end
  end

  def filter_thingiverse_text(content)
    content.gsub(/{(.+?) %!S\(Bool=True\)}/i, "\\1")
  end

  def license_id_from_url(url)
    Spdx.licenses.find { |id, details| details["seeAlso"].map { |it| it.gsub("legalcode", "") }.include?(url.gsub("http:", "https:")) }&.dig(0)
  end

  def tags_from_path_template(library, path)
    return [] unless library.parse_metadata_from_path && library.path_template
    components = PathParserService.new(library.path_template, path).call
    tags = components[:tags] ? components[:tags].map { |tag| tag.titleize.downcase } : []
    tags.delete("@untagged")
    tags
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
    return unless path_component
    if path_component.is_a? Array
      path_component.map { |it| find_or_create_from_path_component(klass, it) }
    else
      klass.find_by(slug: path_component) ||
        klass.create_with(slug: path_component.parameterize).find_or_create_by(
          name: to_human_name(path_component)
        )
    end
  end

  def to_human_name(str)
    str&.humanize&.tr("+", " ")&.careful_titleize
  end

  def combine_options(options, new_options)
    combined = options.reverse_merge(new_options)
    combined[:collections] = (options[:collections] || []).concat(new_options[:collections]).uniq if new_options[:collections]
    combined[:tag_list] = (options[:tag_list] || []).concat(new_options[:tag_list]).uniq if new_options[:tag_list]
    combined.compact_blank
  end
end
