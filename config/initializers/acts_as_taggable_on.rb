ActsAsTaggableOn.remove_unused_tags = true
ActsAsTaggableOn.force_lowercase = false

module ActsAsTaggableOn
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
