# frozen_string_literal: true

# INIT-013/SPEC-002 — minimal SidekiqExt stand-in for skip-middleware specs.
# rails_performance is Gemfile :development/:production only (Engine freezes paths in test).
module RailsPerformanceSidekiqStub
  module_function

  def ensure_loaded!
    return if defined?(RailsPerformance::Gems::SidekiqExt)

    rp = if defined?(RailsPerformance)
      RailsPerformance
    else
      Object.const_set(:RailsPerformance, Module.new)
    end

    gems = if rp.const_defined?(:Gems, false)
      rp.const_get(:Gems)
    else
      rp.const_set(:Gems, Module.new)
    end

    models = if rp.const_defined?(:Models, false)
      rp.const_get(:Models)
    else
      rp.const_set(:Models, Module.new)
    end

    unless models.const_defined?(:SidekiqRecord, false)
      models.const_set(:SidekiqRecord, Class.new {
        attr_accessor :status, :message, :duration

        def initialize(**)
        end

        def save
          true
        end
      })
    end

    unless gems.const_defined?(:SidekiqExt, false)
      # Mirrors rails_performance SidekiqExt: always record.save in ensure.
      gems.const_set(:SidekiqExt, Class.new {
        def call(worker, msg, queue)
          record = RailsPerformance::Models::SidekiqRecord.new(
            queue: queue,
            worker: msg["wrapped"] || worker.class.to_s,
            jid: msg["jid"]
          )
          begin
            yield
          ensure
            record.save
          end
        end
      })
    end
  end
end
