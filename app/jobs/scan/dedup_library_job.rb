# frozen_string_literal: true

# Navbar Scan → Dedup: evaluation-only (INIT-022/SPEC-009, ADR D-11).
# Writes reviewable merge plans. Never applies a model merge.
# Own uniqueness lock — does not hold DetectFilesystemChangesJob's 2h lock.
class Scan::DedupLibraryJob < ApplicationJob
  queue_as :scan
  unique :until_executed, lock_ttl: 30.minutes

  def perform(library_id: nil)
    Scan::DedupLibrary.new(library_id: library_id).call
  end
end
