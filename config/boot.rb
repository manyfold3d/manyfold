ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# Ignore parser/current warning so that it doesn't complain about patchlevel differences
require "warning"
Warning.ignore(/warning: parser\/current/)
