# frozen_string_literal: true

# Re-queue archive mesh preview jobs so listed / previously failed entries get
# real software-rendered PNGs (Assimp → STL → mesh_thumbnail.mjs).
#
# Default scope is listed + preview_failed only (INIT-004/SPEC-001). Pass
# include_ready: true or INCLUDE_READY=1 for an optional honesty re-pass of
# preview_ready rows — off by default so successes are not burned as pending.
#
# Self-chains with a delay so Redis is not flooded with hundreds of thousands
# of jobs at once — drip ~BATCH every (BATCH * STAGGER) seconds.
class Scan::EnqueueArchiveMeshPreviewRerendersJob < ApplicationJob
  queue_as :low
  unique :until_executed, lock_ttl: 6.hours

  DEFAULT_BATCH = 100
  DEFAULT_STAGGER = 0.5
  DEFAULT_STATUSES = %w[listed preview_failed].freeze

  def perform(limit: 0, batch_size: DEFAULT_BATCH, stagger: DEFAULT_STAGGER, cursor: 0, include_ready: false)
    max = (limit.to_i <= 0) ? Float::INFINITY : limit.to_i
    batch = [batch_size.to_i, 1].max
    stagger_s = stagger.to_f
    include_ready = ActiveModel::Type::Boolean.new.cast(include_ready) ||
      ENV["INCLUDE_READY"].to_s == "1"
    statuses = DEFAULT_STATUSES.dup
    statuses << "preview_ready" if include_ready

    scope = ArchiveEntry.meshes
      .where(status: statuses)
      .where("archive_entries.id > ?", cursor.to_i)
      .order(:id)
      .limit([batch, max].min)

    entries = scope.to_a
    return 0 if entries.empty?

    queued = 0
    entries.each_with_index do |entry, index|
      break if queued >= max

      wait = (index * stagger_s).seconds
      entry.update_columns(status: "preview_pending", error_message: nil) # rubocop:disable Rails/SkipsModelValidations
      Scan::ModelFile::PreviewArchiveEntryJob.set(wait: wait).perform_later(entry.id)
      queued += 1
    end

    last_id = entries.last.id
    remaining_cap = max - queued

    Rails.logger.info(
      "[scan] EnqueueArchiveMeshPreviewRerendersJob queued=#{queued} last_id=#{last_id} include_ready=#{include_ready}"
    )

    if remaining_cap > 0 && entries.size >= batch
      # Pace the next drip so the performance queue stays bounded.
      self.class.set(wait: (batch * stagger_s).seconds).perform_later(
        limit: (limit.to_i <= 0) ? 0 : remaining_cap,
        batch_size: batch,
        stagger: stagger_s,
        cursor: last_id,
        include_ready: include_ready
      )
    end

    queued
  end
end
