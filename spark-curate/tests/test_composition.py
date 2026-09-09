"""Composition eligibility fixtures — INIT-022/SPEC-004.

Pure in-memory packs. No NFS, no LLM, no decide_merge.py.
One test per closed verdict + keeper selection + eligible_to_merge matrix.
"""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

_ROOT = Path(__file__).resolve().parents[1]
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

from spark_curate.composition import (  # noqa: E402
    BUNDLE_MESH_COUNT,
    ELIGIBLE_VERDICTS,
    J_COMMONS,
    J_SAME,
    U_UNIQUE_MESH_REFUSE,
    VERDICTS,
    CompositionDecision,
    decide_composition,
    pack_snapshot,
)


def _ids(*names: str) -> tuple[str, ...]:
    return names


def _bundle_ids(prefix: str, n: int = BUNDLE_MESH_COUNT) -> list[str]:
    return [f"{prefix}-{i:03d}" for i in range(n)]


class SamePackTests(unittest.TestCase):
    """ac-1: identical mesh-id sets, Jaccard ≥ J_SAME, uniques both 0 → same_pack."""

    def test_identical_mesh_ids_are_same_pack(self) -> None:
        meshes = _ids("hero.stl|1|aaa", "base.stl|2|bbb", "geo:deadbeef")
        a = pack_snapshot("/lib/Hero", name="Hero", meshes=meshes)
        b = pack_snapshot("/lib/Hero (2)", name="Hero (2)", meshes=meshes)
        d = decide_composition(a, b)
        self.assertEqual(d.verdict, "same_pack")
        self.assertTrue(d.eligible_to_merge)
        self.assertEqual(d.overlap_count, 3)
        self.assertEqual(d.unique_count_a, 0)
        self.assertEqual(d.unique_count_b, 0)
        self.assertGreaterEqual(d.jaccard, J_SAME)
        self.assertAlmostEqual(d.jaccard, 1.0)
        self.assertEqual(d.keeper_path, a.path)


class SubsetTests(unittest.TestCase):
    """ac-2: A ⊂ B (A unique = 0, B extras) → subset; keeper = B."""

    def test_subset_keeper_is_superset(self) -> None:
        core = _ids("body.stl", "head.stl")
        a = pack_snapshot("/lib/Mini", name="Mini", meshes=core)
        b = pack_snapshot("/lib/Full", name="Full", meshes=(*core, "extra_pose.stl"))
        d = decide_composition(a, b)
        self.assertEqual(d.verdict, "subset")
        self.assertTrue(d.eligible_to_merge)
        self.assertEqual(d.unique_count_a, 0)
        self.assertEqual(d.unique_count_b, 1)
        self.assertEqual(d.keeper_path, b.path)

    def test_subset_reversed_keeper_is_superset_a(self) -> None:
        core = _ids("body.stl", "head.stl")
        a = pack_snapshot("/lib/Full", name="Full", meshes=(*core, "extra_pose.stl"))
        b = pack_snapshot("/lib/Mini", name="Mini", meshes=core)
        d = decide_composition(a, b)
        self.assertEqual(d.verdict, "subset")
        self.assertEqual(d.keeper_path, a.path)
        self.assertTrue(d.eligible_to_merge)


class CommonsTests(unittest.TestCase):
    """ac-3 / ac-4: Franken refuse — never same_pack."""

    def test_unique_meshes_each_side_at_cap_is_commons(self) -> None:
        shared = _ids("license.stl")
        only_a = _ids("kit_a1.stl", "kit_a2.stl", "kit_a3.stl")
        only_b = _ids("kit_b1.stl", "kit_b2.stl", "kit_b3.stl")
        self.assertEqual(len(only_a), U_UNIQUE_MESH_REFUSE)
        self.assertEqual(len(only_b), U_UNIQUE_MESH_REFUSE)
        a = pack_snapshot("/lib/DumpA", name="DumpA", meshes=(*shared, *only_a))
        b = pack_snapshot("/lib/DumpB", name="DumpB", meshes=(*shared, *only_b))
        d = decide_composition(a, b)
        self.assertEqual(d.verdict, "commons")
        self.assertFalse(d.eligible_to_merge)
        self.assertGreaterEqual(d.overlap_count, 1)
        self.assertGreaterEqual(d.unique_count_a, U_UNIQUE_MESH_REFUSE)
        self.assertGreaterEqual(d.unique_count_b, U_UNIQUE_MESH_REFUSE)
        self.assertLess(d.jaccard, J_COMMONS)

    def test_jaccard_midband_with_uniques_is_commons_never_same_pack(self) -> None:
        # overlap=3, unique=2 each → Jaccard = 3/7 ≈ 0.429 ∈ (J_COMMONS, J_SAME)
        shared = _ids("m1", "m2", "m3")
        a = pack_snapshot("/lib/P1", name="P1", meshes=(*shared, "ua1", "ua2"))
        b = pack_snapshot("/lib/P2", name="P2", meshes=(*shared, "ub1", "ub2"))
        d = decide_composition(a, b)
        self.assertGreaterEqual(d.jaccard, J_COMMONS)
        self.assertLess(d.jaccard, J_SAME)
        self.assertGreaterEqual(d.unique_count_a, 1)
        self.assertGreaterEqual(d.unique_count_b, 1)
        self.assertEqual(d.verdict, "commons")
        self.assertNotEqual(d.verdict, "same_pack")
        self.assertFalse(d.eligible_to_merge)


class BundleVsNamedTests(unittest.TestCase):
    """ac-5: one pack ≥ BUNDLE_MESH_COUNT, the other below and named."""

    def test_bundle_versus_named_pack(self) -> None:
        named_meshes = _ids("batman_body.stl", "batman_head.stl", "cape.stl")
        bundle = pack_snapshot(
            "/lib/PatreonDump",
            name="PatreonDump",
            meshes=_bundle_ids("dump"),
        )
        named = pack_snapshot("/lib/Batman", name="Batman", meshes=named_meshes)
        self.assertGreaterEqual(len(bundle.mesh_ids), BUNDLE_MESH_COUNT)
        self.assertLess(len(named.mesh_ids), BUNDLE_MESH_COUNT)
        d = decide_composition(bundle, named)
        self.assertEqual(d.verdict, "bundle_vs_named")
        self.assertFalse(d.eligible_to_merge)
        self.assertEqual(d.keeper_path, named.path)

    def test_named_subset_of_bundle_is_still_bundle_not_subset(self) -> None:
        named_meshes = _ids("dump-000", "dump-001")
        bundle = pack_snapshot("/lib/Mega", name="Mega", meshes=_bundle_ids("dump"))
        named = pack_snapshot("/lib/Hero", name="Hero", meshes=named_meshes)
        d = decide_composition(named, bundle)
        self.assertEqual(d.verdict, "bundle_vs_named")
        self.assertFalse(d.eligible_to_merge)


class ImageOnlyTests(unittest.TestCase):
    """ac-6: shared image/preview names only, zero mesh-id overlap → image_only."""

    def test_shared_previews_zero_mesh_overlap(self) -> None:
        a = pack_snapshot(
            "/lib/A",
            name="A",
            meshes=_ids("a_only.stl"),
            images=_ids("preview.jpg", "thumb.png"),
        )
        b = pack_snapshot(
            "/lib/B",
            name="B",
            meshes=_ids("b_only.stl"),
            images=_ids("preview.jpg"),
        )
        d = decide_composition(a, b)
        self.assertEqual(d.overlap_count, 0)
        self.assertEqual(d.verdict, "image_only")
        self.assertFalse(d.eligible_to_merge)
        self.assertEqual(d.shared_image_count, 1)
        self.assertEqual(d.jaccard, 0.0)


class PresupportVariantTests(unittest.TestCase):
    """ac-7: same core + support extras on one side → presupport_variant, not subset."""

    def test_support_name_extras_are_presupport_not_subset(self) -> None:
        core = _ids("body.stl", "head.stl")
        a = pack_snapshot("/lib/Clean", name="Clean", meshes=core)
        b = pack_snapshot(
            "/lib/Supported",
            name="Supported",
            meshes=(*core, "arm_support.stl", "pre-support_raft.stl"),
        )
        d = decide_composition(a, b)
        self.assertEqual(d.verdict, "presupport_variant")
        self.assertNotEqual(d.verdict, "subset")
        self.assertFalse(d.eligible_to_merge)
        self.assertGreaterEqual(d.unique_count_b, 1)
        self.assertEqual(d.unique_count_a, 0)
        self.assertEqual(d.keeper_path, a.path)

    def test_lys_token_and_lattice_flag(self) -> None:
        core = _ids("geo:aaa", "geo:bbb")
        a = pack_snapshot("/lib/Core", name="Core", meshes=core)
        b = pack_snapshot(
            "/lib/Lychee",
            name="Lychee",
            meshes=(*core, "supports.lys"),
            has_support_lattice=True,
        )
        d = decide_composition(a, b)
        self.assertEqual(d.verdict, "presupport_variant")
        self.assertFalse(d.eligible_to_merge)

    def test_analysis_name_is_not_lys_false_positive(self) -> None:
        core = _ids("body.stl")
        a = pack_snapshot("/lib/A", name="A", meshes=core)
        b = pack_snapshot("/lib/B", name="B", meshes=(*core, "analysis.stl"))
        d = decide_composition(a, b)
        self.assertEqual(d.verdict, "subset")
        self.assertTrue(d.eligible_to_merge)


class EligibleMatrixTests(unittest.TestCase):
    """ac-8: eligible_to_merge true only for same_pack and subset."""

    def test_eligible_to_merge_only_same_pack_and_subset(self) -> None:
        fixtures: list[tuple[str, CompositionDecision]] = []
        same = decide_composition(
            pack_snapshot("/a", name="A", meshes=_ids("m1", "m2")),
            pack_snapshot("/b", name="B", meshes=_ids("m1", "m2")),
        )
        subset = decide_composition(
            pack_snapshot("/a", name="A", meshes=_ids("m1")),
            pack_snapshot("/b", name="B", meshes=_ids("m1", "m2")),
        )
        commons = decide_composition(
            pack_snapshot("/a", name="A", meshes=_ids("s", "a1", "a2", "a3")),
            pack_snapshot("/b", name="B", meshes=_ids("s", "b1", "b2", "b3")),
        )
        bundle = decide_composition(
            pack_snapshot("/a", name="Dump", meshes=_bundle_ids("x")),
            pack_snapshot("/b", name="Named", meshes=_ids("n1")),
        )
        image = decide_composition(
            pack_snapshot("/a", name="A", meshes=_ids("aa"), images=_ids("p.jpg")),
            pack_snapshot("/b", name="B", meshes=_ids("bb"), images=_ids("p.jpg")),
        )
        pre = decide_composition(
            pack_snapshot("/a", name="A", meshes=_ids("c1")),
            pack_snapshot("/b", name="B", meshes=_ids("c1", "foo_support.stl")),
        )
        fixtures.extend(
            [
                ("same_pack", same),
                ("subset", subset),
                ("commons", commons),
                ("bundle_vs_named", bundle),
                ("image_only", image),
                ("presupport_variant", pre),
            ]
        )
        seen = {name for name, _ in fixtures}
        self.assertEqual(seen, VERDICTS)
        for name, decision in fixtures:
            self.assertEqual(decision.verdict, name)
            if name in ELIGIBLE_VERDICTS:
                self.assertTrue(decision.eligible_to_merge, name)
            else:
                self.assertFalse(decision.eligible_to_merge, name)


class EmptyAndImageJaccardTests(unittest.TestCase):
    """Edge: empty mesh sets → not eligible. Images do not move Jaccard."""

    def test_empty_mesh_sets_not_eligible(self) -> None:
        a = pack_snapshot("/a", name="A")
        b = pack_snapshot("/b", name="B")
        d = decide_composition(a, b)
        self.assertEqual(d.overlap_count, 0)
        self.assertEqual(d.mesh_count_a, 0)
        self.assertEqual(d.mesh_count_b, 0)
        self.assertFalse(d.eligible_to_merge)
        self.assertNotEqual(d.verdict, "same_pack")
        self.assertNotEqual(d.verdict, "subset")
        self.assertIn(d.verdict, VERDICTS)

    def test_images_do_not_move_jaccard(self) -> None:
        meshes = _ids("only_a.stl")
        a = pack_snapshot(
            "/a",
            name="A",
            meshes=meshes,
            images=_ids("preview.jpg", "alt.png", "extra.webp"),
        )
        b = pack_snapshot(
            "/b",
            name="B",
            meshes=_ids("only_b.stl"),
            images=_ids("preview.jpg", "alt.png", "extra.webp"),
        )
        d = decide_composition(a, b)
        self.assertEqual(d.overlap_count, 0)
        self.assertEqual(d.jaccard, 0.0)
        self.assertEqual(d.shared_image_count, 3)
        self.assertEqual(d.verdict, "image_only")
        self.assertFalse(d.eligible_to_merge)


if __name__ == "__main__":
    unittest.main()
