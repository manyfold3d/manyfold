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

    desc "create", "create a new library (local filesystem only)"
    option :name, required: true, type: :string, description: "library name"
    option :path, required: true, type: :string, description: "local filesystem path"
    def create
      l = Library.create(name: options[:name], path: options[:path], storage_service: "filesystem")
      if l.valid?
        puts "\nNew library created OK"
      else
        puts "\nError when creating library:\n"
        puts l.errors.full_messages.inspect
      end
    end
  end
end
