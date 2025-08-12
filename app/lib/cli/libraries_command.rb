require "thor"

module Cli
  class LibrariesCommand < Thor
    desc "scan", "scan library for filesystem changes"
    def scan
      Library.find_each do |library|
        library.detect_filesystem_changes_later
      end
    end
  end
end
