require "thor"

module Cli
  class ModelsCommand < Thor
    namespace :models
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
      scope.find_each do
        it.pregenerate_downloads delay: 5.seconds, queue: :low
        print "."
        sleep 0.01 # Slows down connections a bit so as not to saturate Redis
      end
      puts "\n#{scope.count} models queued for download creation" # rubocop:disable Pundit/UsePolicyScope
    end

    desc "set_permissions", "set permission preset for all models"
    option :search, required: false, type: :string
    option :preset, required: true, type: :string, enum: %w[private member public]
    def set_permissions
      scope = Model
      scope = Search::ModelSearchService.new(scope).search(options[:search]) if options[:search]
      scope.find_each do
        it.update permission_preset: options[:preset].to_sym
        print "."
        sleep 0.01 # Slows down connections a bit so as not to saturate Redis
      end
      puts "\n#{scope.count} model permissions set to #{options[:preset]}" # rubocop:disable Pundit/UsePolicyScope
    end

    desc "search_model", "search for a model and get matching names and IDs returned"
    option :name, required: true, type: :string, aliases: :n
    option :case_insensitive, required: false, type: :boolean, default: false, aliases: :c # Because the LIKE behavior varies a bit between the available DB options
    def search_model
      query = if options[:case_insensitive]
        "LOWER(name) LIKE LOWER(?)"
      else
        "name LIKE ?"
      end
      models = Model.where(query, options[:name]).pluck(:id, :name) # rubocop:disable Pundit/UsePolicyScope
      if models.empty?
        puts "No models found, please try again."
      else
        puts "Models found: #{models.length}"
        puts "-" * 30
        models.each do |id, name|
          puts "ID: #{id} - Name: #{name}"
        end
      end
    end

    desc "rename_models", "mass rename model names" # If the used DB is postgres, all three options are case-sensitive
    option :search_name, required: true, type: :string, aliases: :s # search name
    option :old_name, required: true, type: :string, aliases: :o # old name
    option :new_name, required: true, type: :string, aliases: :n # new name
    def rename_models
      rename_counter = 0
      models = Model.where("name LIKE ?", options[:search_name]) # rubocop:disable Pundit/UsePolicyScope
      puts "Models found: #{models.count}"
      models.find_each do |model|
        new_name = model.name.gsub(options[:old_name], options[:new_name])
        next if new_name == model.name
        model.update!(name: new_name)
        rename_counter += 1
      end
      puts "Models renamed: #{rename_counter}"
    end
  end
end
