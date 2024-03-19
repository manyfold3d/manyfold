# From https://stackoverflow.com/questions/71262775/how-do-i-ensure-assets-are-present-with-rail-7-cssbundling-rails-jsbundling-ra

# Under Rails 7 with 'cssbundling-rails' and/or the 'jsbundling-rails' gems,
# entirely external systems are used for asset management. With Sprockets no
# longer synchronously building assets on-demand and only when the source files
# changed, compiled assets might be (during local development) or will almost
# always be (CI systems) either out of date or missing when tests are run.
#
# People are used to "bundle exec rspec" and things working. The out-of-box gem
# 'cssbundling-rails' hooks into a vanilla Rails "prepare" task, running a full
# "css:build" task in response. This is quite slow and generates console spam
# on every test run, but points to a slightly better solution for RSpec.
#
# This class is a way of packaging that solution. The class wrapper is really
# just a namespace / container for the code.
#
# First, if you aren't already doing this, add the folllowing lines to
# "spec_helper.rb" somewhere *after* the "require 'rspec/rails'" line:
#
#     require 'rake'
#     YourAppName::Application.load_tasks
#
# ...and call MaintainTestAssets::maintain! (see that method's documentation
# for details). See also constants MaintainTestAssets::ASSET_SOURCE_FOLDERS and
# MaintainTestAssets::EXPECTED_ASSETS for things you may want to customise.
#
class MaintainTestAssets
  # All the places where you have asset files of any kind that you expect to be
  # dynamically compiled/transpiled/etc. via external tooling. The given arrays
  # are passed to "Rails.root.join..." to generate full pathnames.
  #
  # Folders are checked recursively. If any file timestamp therein is greater
  # than (newer than) any of EXPECTED_ASSETS, a rebuild is triggered.
  #
  ASSET_SOURCE_FOLDERS = [
    ["app", "assets", "stylesheets"],
    ["app", "javascript"]
  ]

  # The leaf files that ASSET_SOURCE_FOLDERS will build. These are all checked
  # for in "File.join(Rails.root, 'app', 'assets', 'builds')". Where files are
  # written together - e.g. a ".js" and ".js.map" file - you only need to list
  # any one of the group of concurrently generated files.
  #
  # In a standard JS / CSS combination this would just be 'application.css' and
  # 'application.js', but more complex applications might have added or changed
  # entries in the "scripts" section of 'package.json'.
  #
  EXPECTED_ASSETS = %w[
    application.js
    application.css
  ]

  # Call this method somewhere at test startup, e.g. in "spec_helper.rb" before
  # tests are actually run (just above "RSpec.configure..." works reasonably).
  #
  def self.maintain!
    newest_mtime = 100.years.ago

    # Find the newest modificaftion time across all source files of any type -
    # for simplicity, timestamps of JS vs CSS aren't considered
    #
    ASSET_SOURCE_FOLDERS.each do |relative_array|
      glob_path = Rails.root.join(*relative_array, "**", "*")

      Dir[glob_path].each do |filename|
        next if File.directory?(filename) # NOTE EARLY LOOP RESTART

        source_mtime = File.mtime(filename)
        newest_mtime = source_mtime if source_mtime > newest_mtime
      end
    end

    # Compile the built asset leaf names into full file names for convenience.
    #
    built_assets = EXPECTED_ASSETS.map do |leaf|
      Rails.root.join("app", "assets", "builds", leaf)
    end

    # If any of the source files are newer than expected built assets, or if
    # any of those assets are missing, trigger a rebuild task *and* force a new
    # timestamp on all output assets (just in case build script optimisations
    # result in a file being skipped as "already up to date", which would cause
    # the code here to otherwise keep trying to rebuild it on every run).
    #
    run_build = built_assets.any? do |filename|
      File.exist?(filename) == false || File.mtime(filename) < newest_mtime
    end

    if run_build
      Rake::Task["javascript:build"].invoke
      Rake::Task["css:build"].invoke

      built_assets.each { |filename| FileUtils.touch(filename, nocreate: true) }
    end
  end
end

MaintainTestAssets.maintain!
