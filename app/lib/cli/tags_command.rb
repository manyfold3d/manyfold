require "thor"

module Cli
  class TagsCommand < Thor
    namespace :tags
    DESCRIPTION = "manage tags"

    desc "purge", "removes all tags"
    def purge
      return unless ask("Are you sure you want to remove all tags?", limited_to: %w[y n]) == "y"
      ActsAsTaggableOn::Tagging.destroy_all
      ActsAsTaggableOn::Tag.destroy_all
    end
  end
end
