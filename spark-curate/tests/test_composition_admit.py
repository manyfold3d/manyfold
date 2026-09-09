"""Identity + composition → judge / admit matrix — INIT-022/SPEC-005.

Hermetic. Does not edit decide_merge.py. Admissions JSONL is a record, not apply.
"""
from __future__ import annotations

import inspect
import tempfile
import unittest
from pathlib import Path

from spark_curate.apply_merges import write_merge_plans
from spark_curate.admission import decide_pack, map_signals_for_judge, run_admit
from spark_curate.candidates import MergeCandidate
from spark_curate.composition_map import (
    COMPOSITION_PREFIX,
    GEOMETRY_NEAR_PREFIX,
    GEOMETRY_TWIN,
    MESH_BYTE_DIGEST,
    PROVENANCE_NOCRC,
    library_may_plan_merge,
)
from spark_curate.config import CurateConfig, SparkConfig
from spark_curate.decide_merge import decide_merge_pair
from spark_curate.walk import ModelFolder
from tests.test_admission import (
    ENDPOINT,
    _cand,
    _cfg,
    _health,
    _pack,
    _run,
    _spark,
)


def _library_pair(tmp: Path, signals: list[str]) -> MergeCandidate:
    a = tmp / "DC" / "PackA"
    b = tmp / "DC" / "PackB"
    a.mkdir(parents=True, exist_ok=True)
    b.mkdir(parents=True, exist_ok=True)
    (a / "model.stl").write_bytes(b"a")
    (b / "model.stl").write_bytes(b"b")
    return MergeCandidate(
        a=ModelFolder(path=a, category="DC", name="PackA"),
        b=ModelFolder(path=b, category="DC", name="PackB"),
        signals=list(signals),
    )


def _judge(tmp: Path, signals: list[str]):
    mapped = map_signals_for_judge(signals)
    cand = _library_pair(tmp, mapped)
    return decide_merge_pair(
        cand, SparkConfig(), CurateConfig(min_merge_confidence=0.80), tmp / ".thumbs"
    ), mapped


class Ac1SignalNamesTests(unittest.TestCase):
    def test_ac1_keeps_identity_composition_and_nocrc_provenance(self) -> None:
        raw = [
            "origin_pair:intake_library",
            "archive_member_overlap_nocrc:3",
            GEOMETRY_TWIN,
            f"{GEOMETRY_NEAR_PREFIX}0.12",
            MESH_BYTE_DIGEST,
            f"{MESH_BYTE_DIGEST}:4",
            f"{COMPOSITION_PREFIX}same_pack",
        ]
        mapped = map_signals_for_judge(raw)
        self.assertIn(GEOMETRY_TWIN, mapped)
        self.assertIn(f"{GEOMETRY_NEAR_PREFIX}0.12", mapped)
        self.assertIn(MESH_BYTE_DIGEST, mapped)
        self.assertIn(f"{COMPOSITION_PREFIX}same_pack", mapped)
        self.assertIn("archive_member_overlap_nocrc:3", mapped)
        self.assertIn(PROVENANCE_NOCRC, mapped)
        self.assertIn("archive_member_overlap:3", mapped)


class Ac2TwinEligibleStrongTests(unittest.TestCase):
    def test_ac2_twin_same_pack_is_strong_hold_as_duplicate(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            pack = _pack()
            cand = _cand(
                "Anime/Nezuko",
                "Anime/Live",
                [
                    "origin_pair:intake_library",
                    GEOMETRY_TWIN,
                    f"{COMPOSITION_PREFIX}same_pack",
                ],
            )
            result = _run(tmp, [pack], [cand])
            rec = result.records[0]
            self.assertEqual(rec.verdict, "hold")
            self.assertEqual(rec.reason, "library_duplicate")
            self.assertEqual(rec.band, "STRONG")
            self.assertNotEqual(rec.verdict, "attach")
            self.assertFalse(rec.auto_applicable)

    def test_ac2_twin_subset_library_plans_merge_under_hitl_all(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            d, mapped = _judge(
                root,
                [GEOMETRY_TWIN, f"{COMPOSITION_PREFIX}subset"],
            )
            self.assertEqual(d.decision, "merge")
            self.assertIn("STRONG", d.reason)
            self.assertTrue(library_may_plan_merge(mapped))
            cfg = CurateConfig(
                merge_hitl="hitl_all",
                work_dir=str(root / ".spark-curate"),
                library_root=str(root / "library"),
            )
            Path(cfg.library_root).mkdir()
            out = write_merge_plans(cfg, [d], do_apply=True, run_id="twin-sub")
            self.assertEqual(out["queued_for_manyfold"], 0)
            self.assertEqual(out["merge_hitl"], "hitl_all")
            plans = Path(out["plans_path"])
            self.assertTrue(plans.name.startswith("merges-"))
            self.assertTrue(plans.is_file())
            self.assertIn("merge", plans.read_text(encoding="utf-8"))


class Ac3TwinCommonsRefuseTests(unittest.TestCase):
    def test_ac3_twin_commons_keep_separate_intake_new_when_unique_ge_3(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            pack = _pack()
            cand = _cand(
                "Anime/Nezuko",
                "Anime/KitbashHost",
                [
                    "origin_pair:intake_library",
                    GEOMETRY_TWIN,
                    f"{COMPOSITION_PREFIX}commons",
                    "unique_meshes_intake:3",
                    "archive_member_overlap:4",
                    "shared_archive_member",
                ],
            )
            result = _run(tmp, [pack], [cand])
            rec = result.records[0]
            self.assertEqual(rec.verdict, "new")
            self.assertIsNone(rec.reason)
            self.assertEqual(rec.band, "REFUSE")
            self.assertIn(f"{COMPOSITION_PREFIX}commons", rec.signals)
            self.assertNotIn("archive_member_overlap:4", rec.signals)

        with tempfile.TemporaryDirectory() as tmp:
            d, _mapped = _judge(
                Path(tmp),
                [
                    GEOMETRY_TWIN,
                    f"{COMPOSITION_PREFIX}commons",
                    "archive_member_overlap:4",
                ],
            )
            self.assertEqual(d.decision, "keep_separate")

    def test_ac3_twin_commons_unique_below_cap_holds(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            pack = _pack()
            cand = _cand(
                "Anime/Nezuko",
                "Anime/Kit",
                [
                    "origin_pair:intake_library",
                    GEOMETRY_TWIN,
                    f"{COMPOSITION_PREFIX}commons",
                    "unique_meshes_intake:2",
                ],
            )
            rec = _run(tmp, [pack], [cand]).records[0]
            self.assertEqual(rec.verdict, "hold")
            self.assertEqual(rec.reason, "composition_refuse")
            self.assertNotEqual(rec.verdict, "attach")


class Ac4FrankenNeverAttachTests(unittest.TestCase):
    def test_ac4_bundle_image_presupport_never_attach_or_merge(self) -> None:
        for verdict in ("bundle_vs_named", "image_only", "presupport_variant"):
            with self.subTest(verdict=verdict):
                with tempfile.TemporaryDirectory() as tmp:
                    pack = _pack(rel="Anime/Named", name="Named")
                    cand = _cand(
                        "Anime/Named",
                        "Anime/Dump",
                        [
                            "origin_pair:intake_library",
                            GEOMETRY_TWIN,
                            f"{COMPOSITION_PREFIX}{verdict}",
                            "archive_member_overlap:5",
                        ],
                    )
                    rec = _run(tmp, [pack], [cand]).records[0]
                    self.assertNotEqual(rec.verdict, "attach")
                    self.assertEqual(rec.verdict, "new")
                    self.assertEqual(rec.band, "REFUSE")
                with tempfile.TemporaryDirectory() as tmp:
                    d, mapped = _judge(
                        Path(tmp),
                        [
                            GEOMETRY_TWIN,
                            f"{COMPOSITION_PREFIX}{verdict}",
                            "archive_member_overlap:5",
                        ],
                    )
                    self.assertEqual(d.decision, "keep_separate")
                    self.assertFalse(library_may_plan_merge(mapped))


class Ac5GeometryNearUncertainTests(unittest.TestCase):
    def test_ac5_near_not_twin_is_uncertain_missing_preview_keep_separate(self) -> None:
        signals = [
            f"{GEOMETRY_NEAR_PREFIX}0.35",
            f"{COMPOSITION_PREFIX}same_pack",
        ]
        mapped = map_signals_for_judge(signals)
        self.assertIn("name_near_dupe", mapped)
        self.assertFalse(
            any(s.startswith("archive_member_overlap:") for s in mapped),
            mapped,
        )
        with tempfile.TemporaryDirectory() as tmp:
            d, _ = _judge(Path(tmp), signals)
            self.assertEqual(d.decision, "keep_separate")
            self.assertIn("missing preview", d.reason)


class Ac6NoSecondApplyJsonlTests(unittest.TestCase):
    def test_ac6_admissions_is_record_not_apply(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            pack = _pack()
            cand = _cand(
                "Anime/Nezuko",
                "Anime/Live",
                [
                    "origin_pair:intake_library",
                    GEOMETRY_TWIN,
                    f"{COMPOSITION_PREFIX}same_pack",
                ],
            )
            result = _run(tmp, [pack], [cand])
            work = result.out_path.parent
            self.assertTrue(result.out_path.name.startswith("admissions-"))
            self.assertTrue(result.out_path.is_file())
            self.assertEqual(list(work.glob("merges-*.jsonl")), [])
            self.assertFalse((work / "merges-pending.jsonl").exists())
            payload = result.records[0].to_dict()
            self.assertNotIn("path_a", payload)
            self.assertFalse(result.records[0].auto_applicable)


class Ac7BoundaryNotDecideMergeTests(unittest.TestCase):
    def test_ac7_decide_merge_has_no_geometry_or_composition_map(self) -> None:
        import spark_curate.admission as admission
        import spark_curate.decide_merge as dm

        src = inspect.getsource(dm)
        self.assertNotIn("geometry_twin", src)
        self.assertNotIn("composition:", src)
        self.assertNotIn("mesh_byte_digest", src)
        adm = inspect.getsource(admission)
        self.assertIn("from .composition_map import", adm)
        self.assertIn("map_signals_for_judge", adm)
        self.assertIn("map_signals_for_judge", inspect.getsource(decide_pack))


class RegressionNocrcAndGatesTests(unittest.TestCase):
    def test_listing_nocrc_strong_still_holds(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            pack = _pack()
            cand = _cand(
                "Anime/Nezuko",
                "Anime/Live",
                [
                    "origin_pair:intake_library",
                    "shared_archive_member",
                    "archive_member_overlap_nocrc:3",
                ],
            )
            rec = _run(tmp, [pack], [cand]).records[0]
            self.assertEqual(rec.verdict, "hold")
            self.assertEqual(rec.reason, "library_duplicate")
            self.assertEqual(rec.band, "STRONG")
            self.assertIn("archive_member_overlap_nocrc:3", rec.signals)
            self.assertIn(PROVENANCE_NOCRC, rec.signals)

    def test_franchise_alone_still_refuses(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            d, _ = _judge(Path(tmp), ["franchise_near"])
            self.assertEqual(d.decision, "keep_separate")
            self.assertIn("no structural", d.reason)

    def test_twin_without_composition_is_refuse(self) -> None:
        mapped = map_signals_for_judge([GEOMETRY_TWIN, "archive_member_overlap:4"])
        self.assertNotIn("archive_member_overlap:4", mapped)
        with tempfile.TemporaryDirectory() as tmp:
            pack = _pack()
            cand = _cand(
                "Anime/Nezuko",
                "Anime/Live",
                ["origin_pair:intake_library", GEOMETRY_TWIN],
            )
            rec = _run(tmp, [pack], [cand]).records[0]
            self.assertEqual(rec.verdict, "hold")
            self.assertEqual(rec.reason, "composition_refuse")

    def test_byte_digest_two_files_plus_same_pack_is_strong(self) -> None:
        mapped = map_signals_for_judge(
            [f"{MESH_BYTE_DIGEST}:2", f"{COMPOSITION_PREFIX}same_pack"]
        )
        self.assertIn("shared_digest:2", mapped)
        with tempfile.TemporaryDirectory() as tmp:
            d, _ = _judge(
                Path(tmp),
                [f"{MESH_BYTE_DIGEST}:2", f"{COMPOSITION_PREFIX}same_pack"],
            )
            self.assertEqual(d.decision, "merge")


class HitlAndAdmitHelpersTests(unittest.TestCase):
    def test_hitl_all_and_health_helpers_still_import(self) -> None:
        self.assertEqual(_cfg().merge_hitl, "hitl_all")
        self.assertEqual(ENDPOINT.source, "fixture")
        self.assertIsNotNone(_health())
        self.assertTrue(callable(run_admit))
        self.assertIsInstance(_spark(), SparkConfig)


if __name__ == "__main__":
    unittest.main()
