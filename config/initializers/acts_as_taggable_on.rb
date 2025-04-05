ActsAsTaggableOn.remove_unused_tags = true
ActsAsTaggableOn.force_lowercase = false

module ActsAsTaggableOn
  class Tag
    def self.ransackable_attributes(auth_object = nil)
      ["created_at", "id", "name", "taggings_count", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      ["taggings"]
    end
  end

  class Tagging
    def self.ransackable_attributes(auth_object = nil)
      ["context", "created_at", "id", "tag_id", "taggable_id", "taggable_type", "tagger_id", "tagger_type"]
    end
  end

  class CustomParser < GenericParser
    def parse
      TagList.new.tap do |tag_list|
        tag_list.add @tag_list.map! { |t| t.gsub!(/(^\\*|\\*$)/, "") }
      end
    end
  end
end

ActsAsTaggableOn.default_parser = ActsAsTaggableOn::CustomParser
