# frozen_string_literal: true

require "json"
require "open3"
require "shellwords"

# Evaluation-only library dedup planner (INIT-022/SPEC-009, ADR D-11).
# Writes reviewable merges JSONL. Never applies a model merge.
class Scan::DedupLibrary
  LISTING_STRONG_T = 3
  SPARK_DIR = ".spark-curate"
  PROVENANCE = "INIT-022/SPEC-009"

  class CommandFailed < StandardError; end
  class ConfigurationError < StandardError; end

  def initialize(library_id: nil, spark_curate_cmd: ENV["SPARK_CURATE_CMD"])
    @library_id = library_id
    @spark_curate_cmd = spark_curate_cmd
  end

  def call
    if spark_curate_cmd.present?
      invoke_spark_curate!
    else
      plan_from_archive_entries!
    end
  end

  private

  attr_reader :library_id, :spark_curate_cmd

  def libraries
    scope = Library.all # rubocop:disable Pundit/UsePolicyScope -- system scan of every library
    scope = scope.where(id: library_id) if library_id.present?
    scope
  end

  def invoke_spark_curate!
    argv = Shellwords.split(spark_curate_cmd.to_s)
    if argv.empty?
      raise ConfigurationError, "SPARK_CURATE_CMD is set but empty after split"
    end

    # Config path only — never interpolate request/user params into argv (INIT-022/SPEC-009).
    _stdout, stderr, status = Open3.capture3(*argv)
    unless status.success?
      raise CommandFailed, "SPARK_CURATE_CMD exited #{status.exitstatus}: #{stderr.to_s.strip}"
    end

    {mode: :spark_curate, planned: 0, refused: 0, libraries: 0}
  end

  def plan_from_archive_entries!
    totals = {mode: :archive_entries, planned: 0, refused: 0, libraries: 0}
    libraries.find_each do |library|
      next unless library.storage_service == "filesystem"
      next if library.path.blank?

      result = plan_library(library)
      totals[:planned] += result[:planned]
      totals[:refused] += result[:refused]
      totals[:libraries] += 1
    end
    Rails.logger.info("[scan] DedupLibrary #{totals.inspect} provenance=#{PROVENANCE}")
    totals
  end

  def plan_library(library)
    models = library.models.includes(model_files: :archive_entries).to_a
    packs = {}
    sig_index = Hash.new { |h, k| h[k] = [] }

    models.each do |model|
      pack = pack_for(model)
      next if pack.mesh_ids.empty? && pack.image_ids.empty?

      packs[model.id] = pack
      pack.mesh_ids.each { |sig| sig_index[sig] << model.id }
    end

    pair_ids = Set.new
    sig_index.each_value do |ids|
      uniq = ids.uniq
      next if uniq.size < 2
      uniq.combination(2) { |a, b| pair_ids.add([a, b].minmax) }
    end

    records = pair_ids.filter_map do |id_a, id_b|
      pack_a = packs[id_a]
      pack_b = packs[id_b]
      next if pack_a.nil? || pack_b.nil?

      decision = Scan::Composition.decide(pack_a, pack_b)
      record_for(decision)
    end

    write_jsonl!(library, records)
    planned = records.count { |r| r["decision"] == "merge" }
    {planned: planned, refused: records.size - planned}
  end

  def pack_for(model)
    entries = model.model_files.flat_map(&:archive_entries)
    mesh_ids = entries.filter_map { |e| listing_sig(e) if e.kind == "mesh" }.to_set
    image_ids = entries.filter_map { |e| File.basename(e.pathname) if e.kind == "image" }.to_set
    support_ids = mesh_ids.select { |id| Scan::Composition.support_id?(id) }.to_set
    Scan::Composition.pack_snapshot(
      model.path,
      name: model.name.to_s,
      meshes: mesh_ids,
      images: image_ids,
      supports: support_ids,
      named: model.name.present?
    )
  end

  def listing_sig(entry)
    "#{File.basename(entry.pathname)}|#{entry.size.to_i}"
  end

  def record_for(decision)
    eligible = decision.eligible_to_merge && decision.overlap_count >= LISTING_STRONG_T
    target = if decision.keeper_path == decision.pack_b_path
      "b"
    else
      "a"
    end
    {
      "path_a" => decision.pack_a_path,
      "path_b" => decision.pack_b_path,
      "target" => target,
      "confidence" => eligible ? 0.91 : 0.0,
      "decision" => eligible ? "merge" : "keep_separate",
      "composition" => decision.verdict,
      "overlap_count" => decision.overlap_count,
      "jaccard" => decision.jaccard,
      "reason" => eligible ? "listing STRONG + #{decision.verdict}" : "composition #{decision.verdict} (D-3 refuse or T<#{LISTING_STRONG_T})",
      "merge_hitl" => "hitl_all",
      "provenance" => PROVENANCE
    }
  end

  def write_jsonl!(library, records)
    work = Pathname.new(library.path).join(SPARK_DIR)
    work.mkpath
    stamp = Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
    path = work.join("merges-dedup-#{stamp}.jsonl")
    path.open("w") do |fh|
      records.each { |rec| fh.puts(JSON.generate(rec)) }
    end
    path
  end
end
