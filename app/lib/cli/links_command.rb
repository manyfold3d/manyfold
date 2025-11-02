require "thor"

module Cli
  class LinksCommand < Thor
    COMMAND = "links"
    DESCRIPTION = "manage links"

    desc "deduplicate", "removes duplicate links"
    def deduplicate
      Link.find_duplicated.each(&:remove_duplicates!)
    end

    desc "sync", "run synchronisation with target"
    option :match, required: false, type: :string, description: "only sync links with URLs that match"
    def sync
      scope = Link.all # rubocop:disable Pundit/UsePolicyScope
      scope = scope.where("url LIKE '%#{options[:match]}%'") if options[:match]
      puts "\nQueueing #{scope.count} links for synchronisation"
      scope.find_each(&:update_metadata_from_link_later)
    end

    desc "purge", "remove links"
    option :match, required: true, type: :string, description: "purge links with URLs that match"
    def purge
      scope = Link.where("url LIKE '%#{options[:match]}%'") # rubocop:disable Pundit/UsePolicyScope
      puts "\Removing #{scope.count} links matching #{options[:match]}"
      scope.destroy_all
    end
  end
end
