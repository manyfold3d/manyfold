# frozen_string_literal: true

# INIT-013/SPEC-002 — write-path deny list for rails_performance Sidekiq samples (ADR D-5).
module Performance
  module SkippedWorkers
    # High-churn Turbo stream fan-out — not an operator HTTP bottleneck.
    # Further same-class Turbo broadcast wrappers may be added here without a new ADR.
    NAMES = [
      "Turbo::Streams::BroadcastStreamJob"
    ].freeze

    module_function

    def include?(worker_name)
      NAMES.include?(worker_name.to_s)
    end

    def worker_key_glob(name)
      "*|worker|#{name}|*"
    end
  end
end
