# frozen_string_literal: true

# INIT-013/SPEC-002 — prepend onto RailsPerformance::Gems::SidekiqExt so deny-listed
# workers never call record.save (write-path skip, not a read filter). ADR D-5 / REQ-004.
module Performance
  module SidekiqExtSkip
    def call(worker, msg, queue)
      worker_name = msg["wrapped"] || worker.class.to_s
      if Performance::SkippedWorkers.include?(worker_name)
        return yield
      end

      super
    end

    class << self
      def install!
        return unless defined?(RailsPerformance)

        begin
          require "rails_performance/gems/sidekiq_ext" unless defined?(RailsPerformance::Gems::SidekiqExt)
        rescue LoadError
          return
        end
        return unless defined?(RailsPerformance::Gems::SidekiqExt)
        return if self >= RailsPerformance::Gems::SidekiqExt

        RailsPerformance::Gems::SidekiqExt.prepend(self)
      end
    end
  end
end
