# frozen_string_literal: true

module Print
  # User-asserted consumable inventory helpers (REQ-011). Manager never invents levels.
  class ConsumableService
    class Error < StandardError; end

    def initialize(actor: nil)
      @actor = actor
    end

    def adjust_bottle!(bottle, remaining_ml:)
      authorize_bottle!(bottle)
      raise Error, "remaining_ml required" if remaining_ml.nil?

      ml = remaining_ml.to_d
      raise Error, "remaining_ml must be >= 0" if ml.negative?
      raise Error, "remaining_ml exceeds capacity" if bottle.capacity_ml && ml > bottle.capacity_ml.to_d

      bottle.update!(remaining_ml: ml)
      bottle
    end

    def decrement_bottle!(bottle, ml:)
      authorize_bottle!(bottle)
      amount = ml.to_d
      raise Error, "ml must be > 0" unless amount.positive?

      next_remaining = [bottle.remaining_ml.to_d - amount, 0].max
      bottle.update!(remaining_ml: next_remaining)
      bottle
    end

    # Record a maintenance touch on a vat (FEP cycle bump) and optionally sync host counters.
    def record_vat_maintenance!(vat, fep_cycles: nil, increment_fep: 0, sync_host: true)
      authorize_vat!(vat)
      attrs = {}
      if !fep_cycles.nil?
        attrs[:fep_cycles] = fep_cycles.to_i
      elsif increment_fep.to_i.positive?
        attrs[:fep_cycles] = vat.fep_cycles.to_i + increment_fep.to_i
      end
      vat.update!(attrs) if attrs.any?

      if sync_host && attrs.key?(:fep_cycles)
        vat.print_host.update!(fep_cycles: attrs[:fep_cycles])
      end
      vat
    end

    private

    attr_reader :actor

    def authorize_bottle!(bottle)
      return if actor.nil?
      return unless bottle.print_host
      return if PrintHostPolicy.new(actor, bottle.print_host).control?

      raise Pundit::NotAuthorizedError, "not allowed to adjust consumables"
    end

    def authorize_vat!(vat)
      return if actor.nil?
      return if PrintHostPolicy.new(actor, vat.print_host).control?

      raise Pundit::NotAuthorizedError, "not allowed to record maintenance"
    end
  end
end
