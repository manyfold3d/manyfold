require "thor"

module Cli
  class CollectionsCommand < Thor
    namespace :collections
    DESCRIPTION = "manage collections"

    desc "prune", "removes all empty collections"
    def prune
      Collection.find_each { |it| it.destroy if it.models.empty? && it.collections.empty? }
    end
  end
end
