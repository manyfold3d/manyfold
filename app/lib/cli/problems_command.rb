require "thor"

module Cli
  class ProblemsCommand < Thor
    COMMAND = "problems"
    DESCRIPTION = "manage problems"

    desc "prune", "removes any problems without an associated problematic object"
    def prune
      Upgrade::PruneOrphanedProblems.perform_now
    end

    desc "purge", "removes all problem records"
    option :type, required: false, type: :string, default: nil, aliases: :t, enum: Problem::CATEGORIES
    option :class, required: false, type: :string, default: nil, aliases: :c, enum: %w[Model ModelFile Library]
    def purge
      return unless ask("Are you sure you want to remove all problems", limited_to: %w[y n]) == "y"
      scope = Problem
      scope = scope.where(type: options[:type]) if options[:type]
      scope = scope.where(problematic_type: options[:class]) if options[:class]
      scope.destroy_all
    end
  end
end
