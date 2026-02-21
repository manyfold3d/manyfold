require "thor"

module Cli
  class JobsCommand < Thor
    namespace :jobs
    DESCRIPTION = "manage background jobs"

    desc "unlock", "remove all stale locks that might be preventing jobs from running"
    def unlock
      ActiveJob::Uniqueness.unlock!
    end
  end
end
