# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"
Rails.application.load_tasks

unless ENV["RACK_ENV"] === "production"
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
end

locales = [
  :de,
  :pl
]

namespace :translation do
  namespace :clobber_and_sync do
    task all: locales
    locales.each do |locale|
      task locale => :environment do
        puts "-- Clobbering #{locale}.yml files"
        system "find config/locales -name #{locale}.yml | xargs rm -v"
        puts "-- Downloading from translation.io"
        system "rake translation:sync"
        system "find config/locales -name translation.*.yml | grep -v #{locale} | xargs rm"
        puts "-- Normalizing files"
        system "i18n-tasks normalize -p"
        puts "-- Done!"
      end
    end
  end
end
