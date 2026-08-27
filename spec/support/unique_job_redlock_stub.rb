# frozen_string_literal: true

require "redlock/client"

# INIT-002/SPEC-002: simulate uniqueness Redlock failure without a live Redis.
module UniqueJobRedlockStub
  UNIQUE_JOB_CLASSES = [
    Scan::Model::CheckForProblemsJob,
    Analysis::FileConversionJob
  ].freeze

  def stub_unique_enqueue_redlock_error
    error = Redlock::LockAcquisitionError.new("stubbed uniqueness lock", [])
    UNIQUE_JOB_CLASSES.each do |klass|
      allow_any_instance_of(klass).to receive(:enqueue).and_raise(error)
    end
  end
end

RSpec.configure do |config|
  config.include UniqueJobRedlockStub
end
