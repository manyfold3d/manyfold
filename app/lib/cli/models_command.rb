require "thor"

module Cli
  class ModelsCommand < Thor
    COMMAND = "models"
    DESCRIPTION = "manage models"

    desc "update_metadata", "reruns the metadata parser for all models"
    option :search, required: false, type: :string
    def update_metadata
      Scan::CheckAllJob.perform_later({q: options[:search].presence}, nil)
    end

    desc "pregenerate_downloads", "generate downloadable ZIP files for all models"
    option :search, required: false, type: :string
    def pregenerate_downloads
      if !SiteSettings.pregenerate_downloads
        puts "ERROR: Enable proactive ZIP download creation in admin settings."
        return
      end
      scope = Model
      scope = Search::ModelSearchService.new(scope).search(options[:search]) if options[:search]
      scope.find_each do |it|
        it.pregenerate_downloads delay: 5.seconds, queue: :low
        print "."
        sleep 0.01 # Slows down connections a bit so as not to saturate Redis
      end
      puts "\n#{scope.count} models queued for download creation" # rubocop:disable Pundit/UsePolicyScope
    end
  end
end
