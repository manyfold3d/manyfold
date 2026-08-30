# frozen_string_literal: true

# INIT-013/SPEC-002 — optional ActiveJob wrapper around Performance::Prune.
# Production mutate remains a destructive_shell HITL (initiative); default dry_run.
module Performance
  class PruneJob < ApplicationJob
    queue_as :default

    def perform(dry_run: true)
      Performance::Prune.new(dry_run: dry_run).call
    end
  end
end
