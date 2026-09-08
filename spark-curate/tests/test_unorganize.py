"""Tests for unorganize pass (INIT-021/SPEC-004)."""
from __future__ import annotations

import json
import os
import tempfile
import unittest
from pathlib import Path

from spark_curate.config import CurateConfig
from spark_curate.indexable import (
    COMMON_SUBFOLDERS,
    group_multipart_volumes,
    parse_multipart_volume,
)
from spark_curate.unorganize import (
    SymlinkEscapeRefused,
    assert_intake_contained,
    run_unorganize,
)


def _touch(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(b"x")


class TestIndexableHelpers(unittest.TestCase):
    def test_common_subfolder_count_is_fifteen(self):
        self.assertEqual(len(COMMON_SUBFOLDERS), 15)
        self.assertNotIn("chitubox", COMMON_SUBFOLDERS)
        self.assertNotIn("filesets", COMMON_SUBFOLDERS)

    def test_multipart_rar_grouping(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = [
                root / f"Protectron.part{n:02d}.rar" for n in range(1, 8)
            ]
            for p in paths:
                _touch(p)
            sets, standalone = group_multipart_volumes(paths)
            self.assertEqual(len(sets), 1)
            self.assertEqual(len(sets[0].volumes), 7)
            self.assertEqual(standalone, [])

    def test_incomplete_multipart_detects_gap(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = [
                root / "Protectron.part01.rar",
                root / "Protectron.part02.rar",
                root / "Protectron.part04.rar",
            ]
            for p in paths:
                _touch(p)
            sets, _ = group_multipart_volumes(paths)
            self.assertEqual(len(sets), 1)
            self.assertEqual(sets[0].missing_middle_volume(), 3)


class TestUnorganizePass(unittest.TestCase):
    def _run(self, tree_builder) -> tuple[Path, list[dict]]:
        with tempfile.TemporaryDirectory() as tmp:
            intake = Path(tmp) / "intake"
            intake.mkdir()
            tree_builder(intake)
            cfg = CurateConfig(library_root=str(intake))
            result = run_unorganize(cfg, intake_root=intake, run_id="test")
            plans = [
                json.loads(line)
                for line in result.plan_path.read_text(encoding="utf-8").splitlines()
                if line.strip()
            ]
            return intake, plans

    def test_ac1_bucket_dismantled(self):
        def build(root: Path) -> None:
            _touch(root / "APRIL 2024" / "SomePack" / "stl" / "model.stl")

        _, plans = self._run(build)
        self.assertEqual(len(plans), 1)
        plan = plans[0]
        roles = {lc["name"]: lc["role"] for lc in plan["level_classifications"]}
        self.assertEqual(roles["APRIL 2024"], "bucket")
        if plan["destination"]:
            self.assertNotIn("APRIL 2024", plan["destination"])

    def test_ac2_creator_carried(self):
        def build(root: Path) -> None:
            _touch(
                root
                / "B3Dserk Studios Art"
                / "PackX"
                / "stl"
                / "fig.stl"
            )

        _, plans = self._run(build)
        self.assertEqual(len(plans), 1)
        plan = plans[0]
        self.assertEqual(plan["creator"], "B3Dserk Studios Art")
        roles = {lc["name"]: lc["role"] for lc in plan["level_classifications"]}
        self.assertEqual(roles["B3Dserk Studios Art"], "creator")
        if plan["destination"]:
            self.assertNotIn("B3Dserk Studios Art", plan["destination"])

    def test_ac3_common_subfolder_single_pack(self):
        def build(root: Path) -> None:
            _touch(root / "Pack" / "presupported" / "a.stl")

        _, plans = self._run(build)
        self.assertEqual(len(plans), 1)
        self.assertEqual(plans[0]["pack_name"], "Pack")
        self.assertTrue(
            any(
                s.startswith("indexable_via_common_subfolder:presupported")
                for s in plans[0]["signals"]
            )
        )

    def test_ac3b_single_rar_is_pack(self):
        def build(root: Path) -> None:
            _touch(root / "ArchivePack" / "model.rar")

        _, plans = self._run(build)
        self.assertEqual(len(plans), 1)
        self.assertEqual(plans[0]["pack_name"], "ArchivePack")
        self.assertIn("direct_indexable:.rar", plans[0]["signals"])

    def test_ac3c_multipart_seven_volume_one_pack(self):
        def build(root: Path) -> None:
            pack = root / "Protectron"
            for n in range(1, 8):
                _touch(pack / f"Protectron.part{n:02d}.rar")

        _, plans = self._run(build)
        self.assertEqual(len(plans), 1)
        plan = plans[0]
        self.assertEqual(len(plan["multipart_sets"]), 1)
        self.assertEqual(len(plan["multipart_sets"][0]["volumes"]), 7)
        self.assertNotIn("incomplete_multipart", plan["flags"])

    def test_ac3c_incomplete_multipart_hold(self):
        def build(root: Path) -> None:
            pack = root / "BrokenSet"
            _touch(pack / "BrokenSet.part01.rar")
            _touch(pack / "BrokenSet.part02.rar")
            _touch(pack / "BrokenSet.part04.rar")

        _, plans = self._run(build)
        self.assertEqual(len(plans), 1)
        plan = plans[0]
        self.assertEqual(plan["status"], "hold")
        self.assertIn("incomplete_multipart", plan["flags"])
        self.assertIsNone(plan["destination"])

    def test_ac4_multi_pack_container(self):
        def build(root: Path) -> None:
            _touch(root / "Container" / "PackA" / "stl" / "a.stl")
            _touch(root / "Container" / "PackB" / "stl" / "b.stl")

        _, plans = self._run(build)
        self.assertEqual(len(plans), 2)
        names = {p["pack_name"] for p in plans}
        self.assertEqual(names, {"PackA", "PackB"})
        container_roles = [
            lc["role"]
            for p in plans
            for lc in p["level_classifications"]
            if lc["name"] == "Container"
        ]
        self.assertTrue(all(r in ("bucket", "unknown") for r in container_roles))
        self.assertFalse(any(p["pack_name"] == "Container" for p in plans))

    def test_ac5_plan_record_has_evidence(self):
        def build(root: Path) -> None:
            _touch(root / "Anime" / "Hero" / "stl" / "h.stl")

        intake, plans = self._run(build)
        plan = plans[0]
        self.assertTrue(plan["source_path"].startswith(str(intake.resolve())))
        self.assertEqual(plan["destination"], "Anime/Hero")
        self.assertTrue(plan["level_classifications"])
        self.assertTrue(plan["signals"])
        self.assertEqual(plan["provenance"], "INIT-021/SPEC-004")

    def test_ac6_unknown_emits_candidates(self):
        def build(root: Path) -> None:
            _touch(root / "MysteryFolder" / "Pack1" / "stl" / "x.stl")

        _, plans = self._run(build)
        plan = plans[0]
        mystery = next(
            lc for lc in plan["level_classifications"] if lc["name"] == "MysteryFolder"
        )
        self.assertEqual(mystery["role"], "unknown")
        self.assertIn("candidate_roles", mystery)

    def test_ac7_symlink_escape_refused(self):
        with tempfile.TemporaryDirectory() as tmp:
            intake = Path(tmp) / "intake"
            outside = Path(tmp) / "outside"
            intake.mkdir()
            outside.mkdir()
            _touch(outside / "secret.stl")
            link = intake / "escape"
            link.symlink_to(outside, target_is_directory=True)
            cfg = CurateConfig(library_root=str(intake))
            result = run_unorganize(cfg, intake_root=intake, run_id="symlink")
            self.assertTrue(result.errors)
            with self.assertRaises(SymlinkEscapeRefused):
                assert_intake_contained(link, intake.resolve())

    def test_ac8_plan_under_spark_curate(self):
        with tempfile.TemporaryDirectory() as tmp:
            intake = Path(tmp) / "intake"
            intake.mkdir()
            _touch(intake / "Anime" / "X" / "stl" / "a.stl")
            cfg = CurateConfig(library_root=str(intake))
            result = run_unorganize(cfg, intake_root=intake, run_id="ac8")
            self.assertIn(".spark-curate", str(result.plan_path))
            self.assertTrue(result.plan_path.name.startswith("unorganize-plan-"))
            # No files moved — source still present
            self.assertTrue((intake / "Anime" / "X" / "stl" / "a.stl").is_file())

    def test_ac9_macosx_mirror_one_pack(self):
        def build(root: Path) -> None:
            _touch(root / "RealPack" / "stl" / "body.stl")
            _touch(
                root
                / "RealPack"
                / "__MACOSX"
                / "stl"
                / "._body.stl"
            )

        _, plans = self._run(build)
        self.assertEqual(len(plans), 1)
        self.assertEqual(plans[0]["pack_name"], "RealPack")

    def test_deterministic_ordering(self):
        def build(root: Path) -> None:
            _touch(root / "Anime" / "B" / "stl" / "b.stl")
            _touch(root / "Anime" / "A" / "stl" / "a.stl")

        _, plans_a = self._run(build)
        _, plans_b = self._run(build)
        self.assertEqual(
            [p["rel_pack_root"] for p in plans_a],
            [p["rel_pack_root"] for p in plans_b],
        )
        self.assertEqual(plans_a[0]["rel_pack_root"], "Anime/A")

    def test_category_destination_anime(self):
        def build(root: Path) -> None:
            _touch(root / "APRIL 2024" / "Anime" / "Nezuko" / "stl" / "n.stl")

        _, plans = self._run(build)
        self.assertEqual(len(plans), 1)
        self.assertEqual(plans[0]["destination"], "Anime/Nezuko")
        self.assertNotIn("APRIL 2024", plans[0]["destination"] or "")


class TestMultipartParse(unittest.TestCase):
    def test_parse_part_rar(self):
        vol = parse_multipart_volume(Path("Foo.part03.rar"))
        self.assertIsNotNone(vol)
        assert vol is not None
        self.assertEqual(vol.stem_key, "foo")
        self.assertEqual(vol.volume_num, 3)


if __name__ == "__main__":
    unittest.main()
