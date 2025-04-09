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
      string = @tag_list

      string = string.join(ActsAsTaggableOn.glue) if string.respond_to?(:join)
      TagList.new.tap do |tag_list|
        string = string.to_s.dup
        string.gsub!(/(^\\*|\\*$)/, "").gsub!(/(, \\*|\\*, )/, ",")

        tag_list.add(string.split(ActsAsTaggableOn.delimiter))
      end
    end
  end
end

ActsAsTaggableOn.default_parser = ActsAsTaggableOn::CustomParser
