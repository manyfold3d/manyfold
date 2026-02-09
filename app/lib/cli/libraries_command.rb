require "thor"

module Cli
  class LibrariesCommand < Thor
    namespace :libraries
    DESCRIPTION = "manage libraries"

    desc "scan", "scan library for filesystem changes"
    option :name, required: false, type: :string, description: "library name to be scanned"
    def scan
      scope = Library.all # rubocop:disable Pundit/UsePolicyScope
      scope = scope.where(name: options[:name]) if options[:name].presence
      puts "\nQueueing #{scope.count} #{"library".pluralize(scope.count)} for filesystem scan"
      scope.find_each(&:detect_filesystem_changes_later)
    end
  end
end
