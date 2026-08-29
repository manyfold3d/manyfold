# frozen_string_literal: true

module Print
  # Queue / control lifecycle for Print Studio jobs (REQ-006, REQ-009, GR-002).
  # Never auto-starts the next job; plate-cleared is an explicit manager ack.
  class JobService
    class Error < StandardError; end

    class ConfirmationRequired < Error; end

    class PlateNotCleared < Error; end

    class GateFailed < Error
      attr_reader :result

      def initialize(result)
        @result = result
        codes = result.reasons.map(&:code).join(", ")
        super("Compatibility gate failed: #{codes}")
      end
    end

    class Busy < Error; end

    class InvalidState < Error; end

    def initialize(print_host:, actor: nil, sdcp: nil)
      @print_host = print_host
      @actor = actor
      @sdcp = sdcp
    end

    # Creates a durable PrintJob. Initial state is waiting_plate when a prior
    # success on this host still lacks plate_cleared_at; otherwise queued.
    # Does not upload or start.
    def create!(attrs = {})
      authorize_mutate!
      stamp = attrs.delete(:stamp) || stamp_from(attrs[:sliced_artifact])
      gate = CompatibilityGate.call(print_host: print_host, stamp: stamp) if stamp.present?
      raise GateFailed, gate if gate&.fail?

      state = plate_block_active? ? :waiting_plate : :queued
      print_host.print_jobs.create!(
        attrs.merge(
          state: state,
          user: attrs[:user] || actor,
          layer_count: attrs[:layer_count] || attrs[:sliced_artifact]&.estimated_layers,
          estimated_duration_seconds: attrs[:estimated_duration_seconds] ||
            attrs[:sliced_artifact]&.estimated_duration_seconds,
          estimated_resin_ml: attrs[:estimated_resin_ml] ||
            attrs[:sliced_artifact]&.estimated_resin_ml
        )
      )
    end

    # Enqueues background upload (does not start print).
    def upload!(print_job, io: nil, filename: nil, enqueue: true)
      authorize_mutate!
      assert_job_host!(print_job)
      raise InvalidState, "job is terminal" if print_job.terminal?

      filename ||= filename_for(print_job)
      raise Error, "filename required" if filename.blank?

      if enqueue && io.nil?
        UploadPrintJobFileJob.perform_later(print_job.id)
        return print_job
      end

      raise Error, "io required for synchronous upload" if io.nil?

      assert_storage_room!(bytes: io.respond_to?(:size) ? io.size : nil)
      sdcp.upload(io: io, filename: filename, start: false)
      print_job
    end

    # Starts a remote print. Requires confirm: true (REQ-006). Never starts when
    # a prior success lacks plate_cleared_at (REQ-009 / GR-002).
    def start!(print_job, confirm:, filename: nil, start_layer: 0)
      authorize_mutate!
      assert_job_host!(print_job)
      raise ConfirmationRequired, "confirm: true is required to start a remote print" unless confirm == true
      raise InvalidState, "job is terminal" if print_job.terminal?
      raise Busy, "host already has a printing job" if active_printing.exists?
      raise PlateNotCleared, "prior success awaits plate-cleared ack" if plate_block_active?

      stamp = stamp_from(print_job.sliced_artifact) || {format: File.extname(filename_for(print_job)).delete(".")}
      gate = CompatibilityGate.call(print_host: print_host, stamp: stamp)
      raise GateFailed, gate if gate.fail?

      filename ||= filename_for(print_job)
      sdcp.start_print(filename: filename, start_layer: start_layer)

      print_job.update!(
        state: :printing,
        started_at: print_job.started_at || Time.current,
        current_layer: print_job.current_layer || 0
      )
      print_job
    end

    def pause!(print_job)
      authorize_mutate!
      assert_job_host!(print_job)
      raise InvalidState, "job must be printing to pause" unless print_job.printing?

      sdcp.pause_print
      print_job.update!(state: :paused)
      print_job
    end

    def resume!(print_job)
      authorize_mutate!
      assert_job_host!(print_job)
      raise InvalidState, "job must be paused to resume" unless print_job.paused?
      raise Busy, "host already has a printing job" if active_printing.where.not(id: print_job.id).exists?

      sdcp.continue_print
      print_job.update!(state: :printing)
      print_job
    end

    def cancel!(print_job, note: nil)
      authorize_mutate!
      assert_job_host!(print_job)
      raise InvalidState, "job is already terminal" if print_job.terminal?

      if print_job.printing? || print_job.paused?
        sdcp.stop_print
      end

      finalize!(print_job, outcome: :cancelled, failure_note: note)
    end

    # Marks a succeeded job's plate as cleared. Promotes waiting_plate → queued.
    # NEVER auto-starts the next job (GR-002).
    def confirm_plate_cleared!(print_job, at: Time.current)
      authorize_mutate!
      assert_job_host!(print_job)
      raise InvalidState, "only succeeded jobs accept plate-cleared" unless print_job.succeeded?

      print_job.update!(plate_cleared_at: at)
      promote_waiting_plate_to_queued!
      print_job
    end

    # Apply a terminal outcome and fill history fields (REQ-008).
    # Optional resin bottle decrement by estimated_ml (user-asserted inventory).
    def finalize!(print_job, outcome:, failure_note: nil, actual_duration_seconds: nil,
      actual_resin_ml: nil, resin_bottle: nil, decrement_resin: true)
      authorize_mutate!
      assert_job_host!(print_job)

      outcome_sym = outcome.to_sym
      unless %i[succeeded failed cancelled].include?(outcome_sym)
        raise ArgumentError, "invalid outcome #{outcome.inspect}"
      end

      finished = Time.current
      duration = actual_duration_seconds
      if duration.nil? && print_job.started_at
        duration = (finished - print_job.started_at).to_i
      end

      resin_used = actual_resin_ml
      resin_used = print_job.estimated_resin_ml if resin_used.nil? && outcome_sym == :succeeded

      print_job.update!(
        state: outcome_sym,
        outcome: outcome_sym.to_s,
        failure_note: (outcome_sym == :failed) ? failure_note : print_job.failure_note,
        finished_at: finished,
        actual_duration_seconds: duration,
        actual_resin_ml: resin_used,
        # Successful finish leaves plate uncleared until explicit ack
        plate_cleared_at: (outcome_sym == :succeeded) ? nil : print_job.plate_cleared_at
      )

      if decrement_resin && resin_used.present? && resin_used.to_d.positive?
        bottle = resin_bottle || default_resin_bottle
        ConsumableService.new(actor: actor).decrement_bottle!(bottle, ml: resin_used) if bottle
      end

      # Hold subsequent queued work behind plate-cleared after success — never auto-start.
      if outcome_sym == :succeeded
        hold_queued_for_plate!
      end

      print_job
    end

    def plate_block_active?
      print_host.print_jobs
        .where(state: :succeeded, plate_cleared_at: nil)
        .exists?
    end

    private

    attr_reader :print_host, :actor

    def sdcp
      @sdcp ||= print_host.service
    end

    def authorize_mutate!
      return if actor.nil? # caller owns authz (jobs / system)
      return if PrintHostPolicy.new(actor, print_host).control?

      raise Pundit::NotAuthorizedError, "not allowed to control print host"
    end

    def assert_job_host!(print_job)
      raise Error, "print_job required" unless print_job
      return if print_job.print_host_id == print_host.id

      raise Error, "print_job does not belong to this print_host"
    end

    def active_printing
      print_host.print_jobs.where(state: :printing)
    end

    def hold_queued_for_plate!
      print_host.print_jobs.where(state: :queued).find_each do |job|
        job.update!(state: :waiting_plate)
      end
    end

    def promote_waiting_plate_to_queued!
      print_host.print_jobs.where(state: :waiting_plate).find_each do |job|
        job.update!(state: :queued)
      end
    end

    def stamp_from(artifact)
      return nil unless artifact

      {format: artifact.format}
    end

    def filename_for(print_job)
      if print_job.model_file&.filename.present?
        return File.basename(print_job.model_file.filename.to_s)
      end
      return nil unless print_job.sliced_artifact&.format.present?

      "job-#{print_job.id}.#{print_job.sliced_artifact.format}"
    end

    def assert_storage_room!(bytes:)
      return if bytes.nil?

      free = sdcp.storage_free_bytes
      return if free.nil?
      return if bytes <= free

      raise Error, "insufficient on-printer storage (need #{bytes}, free #{free})"
    end

    def default_resin_bottle
      print_host.resin_bottles.order(updated_at: :desc).first
    end
  end
end
