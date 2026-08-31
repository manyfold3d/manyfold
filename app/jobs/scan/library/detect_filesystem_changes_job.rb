# frozen_string_literal: true

require "digest"

# INIT-016/SPEC-002: optional path_prefixes + scope-aware uniqueness fingerprint (ADR D-3…D-5, D-7).
class Scan::Library::DetectFilesystemChangesJob < ApplicationJob
  queue_as :scan
  unique :until_executed, lock_ttl: 2.hours

  def folders_with_changes(library, path_prefixes: nil) = detector.folders_with_changes(library, path_prefixes: path_prefixes)
  def filenames_on_disk(library) = detector.filenames_on_disk(library)
  def known_filenames(library) = detector.known_filenames(library)
  def models_with_new_files(library, since: :auto) = detector.models_with_new_files(library, since: since)
  def missing_file_model_paths(library) = detector.missing_file_model_paths(library)

  def perform(library_id, path_prefixes: nil)
    library = Library.find(library_id)
    return if Problems::MissingLibrary.detect(library)

    if ::Model.column_names.include?("scan_started_at")
      ::Model.where(library_id: library.id)
        .where(scan_started_at: ...1.hour.ago)
        .update_all(scan_started_at: nil) # rubocop:disable Rails/SkipsModelValidations
    end

    # Capture watermark before discover's remember_detect_at! so known-model refresh stays correct.
    since = detector.last_detect_at(library)
    sanitized_prefixes = detector.sanitize_path_prefixes(library, path_prefixes)

    # INIT-016/SPEC-005 SEC-001: non-nil path_prefixes that sanitize to empty must fail closed —
    # never fall through to a whole-library discover + CheckMissingFiles (DoS / uniqueness bypass).
    # Lock fingerprint may remain scoped (lexical); this path is a short no-op on that key.
    if !path_prefixes.nil? && sanitized_prefixes.empty?
      Rails.logger.warn(
        "[scan] library=#{library.id} reason=empty_after_sanitize " \
        "prefixes_given=#{Array(path_prefixes).size} — aborting scoped detect " \
        "(no discover, no CheckMissingFiles)"
      )
      return
    end

    scoped = sanitized_prefixes.any?

    new_model_paths = folders_with_changes(library, path_prefixes: path_prefixes)
    refresh_model_ids = models_with_new_files(library, since: since)

    scan_batch_id = SecureRandom.uuid
    status[:step] = "jobs.scan.detect_filesystem_changes.creating_models" # i18n-tasks-use t('jobs.scan.detect_filesystem_changes.creating_models')

    Rails.logger.info(
      "[scan] library=#{library.id} new_models=#{new_model_paths.size} " \
      "refresh_models=#{refresh_model_ids.size} batch=#{scan_batch_id} " \
      "scoped=#{scoped} prefixes=#{sanitized_prefixes.size}"
    )

    new_model_paths.each_with_index do |path, index|
      delay = [index * 0.05, 30.0].min.seconds
      library.create_model_from_path_later(path, delay: delay, scan_batch_id: scan_batch_id)
    end

    refresh_model_ids.each_with_index do |model_id, index|
      delay = [index * 0.05, 30.0].min.seconds
      model = ::Model.find_by(id: model_id)
      next unless model

      model.add_new_files_later(delay: delay, scan_batch_id: scan_batch_id)
    end

    # INIT-016/SPEC-002 D-5: skip library-wide CheckMissingFiles on scoped detect.
    return if scoped

    Scan::Library::CheckMissingFilesJob.set(wait: 5.seconds)
      .perform_later(library.id, scan_batch_id: scan_batch_id)
  end

  # D-4: whole-library lock uses "full"; scoped uses digest of sorted normalized prefixes.
  # A scoped job does not share the uniqueness key of whole-library detect.
  # While a full detect holds the 2h lock, operators should not re-click full Scan;
  # scoped detect and CreateModelFromPathJob still proceed on their own keys.
  def lock_key_arguments
    [arguments.first, self.class.scope_lock_fingerprint(path_prefixes_from_arguments)]
  end

  def self.scope_lock_fingerprint(path_prefixes)
    list = Array(path_prefixes).filter_map { |p| normalize_prefix_for_lock(p) }.uniq.sort
    return "full" if list.empty?

    "scoped:#{Digest::SHA256.hexdigest(list.join("\0"))}"
  end

  def self.normalize_prefix_for_lock(raw)
    return nil if raw.nil?

    str = raw.to_s
    return nil if str.empty?
    return nil if str.match?(/[\x00-\x1f\x7f]/)
    return nil if str.start_with?("/", "\\")
    return nil if str.match?(/\A[A-Za-z]:[\\\/]/)

    cleaned = str.tr("\\", "/").squeeze("/").delete_prefix("/").delete_suffix("/")
    return nil if cleaned.empty?

    parts = cleaned.split("/")
    return nil if parts.any? { |p| p == ".." || p == "." || p.empty? }

    parts.join("/")
  end

  private

  def path_prefixes_from_arguments
    trailing = arguments[1]
    return nil unless trailing.is_a?(Hash)

    trailing[:path_prefixes] || trailing["path_prefixes"]
  end

  def detector
    @detector ||= Scan::Library::FilesystemChangeDetector.new(status: status)
  end
end
