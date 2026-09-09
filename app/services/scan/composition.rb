# frozen_string_literal: true

# Rails port of spark_curate.composition (INIT-022/SPEC-004).
# Pure evaluator — identity is not eligibility. Default is refuse merge, not same_pack.
# INIT-022/SPEC-009
class Scan::Composition
  J_SAME = 0.90
  J_COMMONS = 0.40
  U_UNIQUE_MESH_REFUSE = 3
  BUNDLE_MESH_COUNT = 80
  ELIGIBLE_VERDICTS = %w[same_pack subset].freeze
  VERDICTS = %w[same_pack subset commons bundle_vs_named presupport_variant image_only].freeze
  SUPPORT_RE = /(?:support|pre-?support|(?:^|[.\\\/_-])lys(?:[^a-z0-9]|$))/i

  PackSnapshot = Data.define(
    :path,
    :name,
    :mesh_ids,
    :image_ids,
    :support_mesh_ids,
    :has_support_lattice,
    :named
  )

  Decision = Data.define(
    :verdict,
    :eligible_to_merge,
    :jaccard,
    :overlap_count,
    :unique_count_a,
    :unique_count_b,
    :keeper_path,
    :pack_a_path,
    :pack_b_path,
    :mesh_count_a,
    :mesh_count_b,
    :shared_image_count
  )

  def self.pack_snapshot(path, name: "", meshes: [], images: [], supports: [], has_support_lattice: false, named: nil)
    PackSnapshot.new(
      path: path,
      name: name.to_s,
      mesh_ids: meshes.to_set,
      image_ids: images.to_set,
      support_mesh_ids: supports.to_set,
      has_support_lattice: has_support_lattice,
      named: named
    )
  end

  def self.support_id?(mesh_id)
    SUPPORT_RE.match?(mesh_id.to_s)
  end

  def self.decide(pack_a, pack_b)
    new.decide(pack_a, pack_b)
  end

  def decide(pack_a, pack_b)
    ids_a = pack_a.mesh_ids.to_set
    ids_b = pack_b.mesh_ids.to_set
    overlap_ids = ids_a & ids_b
    only_a = ids_a - ids_b
    only_b = ids_b - ids_a
    union_size = (ids_a | ids_b).size
    overlap = overlap_ids.size
    unique_a = only_a.size
    unique_b = only_b.size
    jaccard = (union_size <= 0) ? 0.0 : (overlap.to_f / union_size)
    count_a = ids_a.size
    count_b = ids_b.size
    shared_image_count = (pack_a.image_ids.to_set & pack_b.image_ids.to_set).size

    verdict = classify(
      overlap: overlap,
      unique_a: unique_a,
      unique_b: unique_b,
      jaccard: jaccard,
      count_a: count_a,
      count_b: count_b,
      pack_a: pack_a,
      pack_b: pack_b,
      only_a: only_a,
      only_b: only_b
    )
    unless VERDICTS.include?(verdict)
      raise ArgumentError, "illegal composition verdict: #{verdict.inspect}"
    end

    Decision.new(
      verdict: verdict,
      eligible_to_merge: ELIGIBLE_VERDICTS.include?(verdict),
      jaccard: jaccard,
      overlap_count: overlap,
      unique_count_a: unique_a,
      unique_count_b: unique_b,
      keeper_path: keeper_path(verdict, pack_a, pack_b, unique_a, unique_b),
      pack_a_path: pack_a.path,
      pack_b_path: pack_b.path,
      mesh_count_a: count_a,
      mesh_count_b: count_b,
      shared_image_count: shared_image_count
    )
  end

  private

  def named?(pack)
    return false if pack.named == false
    return true if pack.named == true
    pack.name.to_s.strip.present?
  end

  def uniques_are_supports?(pack, uniques)
    return false if uniques.empty?
    return true if pack.has_support_lattice
    uniques.all? { |uid| pack.support_mesh_ids.include?(uid) || self.class.support_id?(uid) }
  end

  def keeper_path(verdict, pack_a, pack_b, unique_a, unique_b)
    case verdict
    when "subset"
      (unique_a == 0) ? pack_b.path : pack_a.path
    when "presupport_variant"
      (unique_a == 0) ? pack_a.path : pack_b.path
    when "bundle_vs_named"
      count_a = pack_a.mesh_ids.size
      count_b = pack_b.mesh_ids.size
      if count_a >= BUNDLE_MESH_COUNT && count_b < BUNDLE_MESH_COUNT && named?(pack_b)
        pack_b.path
      elsif count_b >= BUNDLE_MESH_COUNT && count_a < BUNDLE_MESH_COUNT && named?(pack_a)
        pack_a.path
      else
        pack_a.path
      end
    else
      pack_a.path
    end
  end

  def classify(overlap:, unique_a:, unique_b:, jaccard:, count_a:, count_b:, pack_a:, pack_b:, only_a:, only_b:)
    a_bundle = count_a >= BUNDLE_MESH_COUNT && count_b < BUNDLE_MESH_COUNT && named?(pack_b)
    b_bundle = count_b >= BUNDLE_MESH_COUNT && count_a < BUNDLE_MESH_COUNT && named?(pack_a)
    return "bundle_vs_named" if a_bundle || b_bundle

    return "same_pack" if overlap >= 1 && unique_a == 0 && unique_b == 0 && jaccard >= J_SAME

    if overlap >= 1 && unique_a == 0 && unique_b >= 1 && uniques_are_supports?(pack_b, only_b)
      return "presupport_variant"
    end
    if overlap >= 1 && unique_b == 0 && unique_a >= 1 && uniques_are_supports?(pack_a, only_a)
      return "presupport_variant"
    end

    return "subset" if overlap >= 1 && unique_a == 0 && unique_b >= 1
    return "subset" if overlap >= 1 && unique_b == 0 && unique_a >= 1

    both_unique = unique_a >= 1 && unique_b >= 1
    if overlap >= 1 && unique_a >= U_UNIQUE_MESH_REFUSE && unique_b >= U_UNIQUE_MESH_REFUSE
      return "commons"
    end
    return "commons" if both_unique && jaccard >= J_COMMONS
    return "image_only" if overlap == 0

    "commons"
  end
end
