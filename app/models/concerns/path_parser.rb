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
    if SiteSettings.model_tags_tag_model_path_prefix
      filepaths = File.dirname(path).split("/")
      filepaths.shift
      templatechunks = SiteSettings.model_path_prefix_template.split("/")
      creatornew = ""
      collectionnew = ""
      tags = []
      while !templatechunks.empty? && !filepaths.empty? && !(templatechunks.length == 1 && templatechunks[0] == "{tags}")
        if templatechunks[0] == "{creator}"
          creatornew = filepaths.shift
          templatechunks.shift
        elsif templatechunks[0] == "{collection}"
          collectionnew = filepaths.shift
          templatechunks.shift
        elsif templatechunks[-1] == "{creator}"
          creatornew = filepaths.pop
          templatechunks.pop
        elsif templatechunks[-1] == "{collection}"
          collectionnew = filepaths.pop
          templatechunks.pop
        else
          logger.error "Invalid model_path_prefix_template: #{SiteSettings.model_path_prefix_template} / #{templatechunks[0]}"
          templatechunks.shift
        end
      end
      if templatechunks.length == 1 && templatechunks[0] == "{tags}"
        tags = filepaths
      end
      unless tags.empty?
        tag_list.add(remove_stop_words(tags))
      end
      unless creatornew.empty?
        creator = Creator.find_by(name: creatornew)
        creator ||= Creator.create(name: creatornew)
        self.creator_id = creator.id
      end
      unless collectionnew.empty? && !collection_list
        collection_list.add(collectionnew)
      end
      save!
    end
  end
end

def remove_stop_words(words)
  return words if !SiteSettings.model_tags_filter_stop_words
  stopword_filter = Stopwords::Snowball::Filter.new(
    SiteSettings.model_tags_stop_words_locale,
    SiteSettings.model_tags_custom_stop_words
  )
  stopword_filter.filter(words)
end
