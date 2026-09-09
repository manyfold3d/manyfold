"""Move-script jail + reverse-manifest rollback (INIT-021/SPEC-011).

Exercises manyfold-intake-move-admitted.sh on a temp tree only — never the
live library or intake/Mega.
"""
from __future__ import annotations

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools" / "manyfold-intake-move-admitted.sh"


def _write_pack(root: Path, rel: str) -> Path:
    pack = root / rel
    pack.mkdir(parents=True)
    (pack / "m.stl").write_bytes(b"stl")
    return pack


def _admissions(path: Path, rows: list[dict]) -> Path:
    path.write_text("".join(json.dumps(r) + "\n" for r in rows), encoding="utf-8")
    return path


def _run(
    intake: Path,
    library: Path,
    adm: Path,
    *,
    apply: bool = False,
    copy: bool = True,
    extra_env: dict[str, str] | None = None,
    dest_override: str | None = None,
) -> subprocess.CompletedProcess[str]:
    if dest_override is not None:
        text = adm.read_text(encoding="utf-8")
        rec = json.loads(text.splitlines()[0])
        rec["destination"] = dest_override
        adm.write_text(json.dumps(rec) + "\n", encoding="utf-8")
    env = os.environ.copy()
    env.update(
        {
            "FLOOR_BYTES": "1",
            "MIN_INODES": "0",
            "PATH": os.environ.get("PATH", "/usr/bin"),
        }
    )
    if extra_env:
        env.update(extra_env)
    argv = [
        "bash",
        str(SCRIPT),
        "--admissions",
        str(adm),
        "--slice",
        "Games",
        "--intake",
        str(intake),
        "--library",
        str(library),
        "--work-dir",
        str(intake / ".spark-curate"),
        "--copy" if copy else "--dry-run",
    ]
    if apply:
        argv.append("--apply")
    elif "--dry-run" not in argv:
        argv.append("--dry-run")
    return subprocess.run(argv, capture_output=True, text=True, env=env)


class DestJailTests(unittest.TestCase):
    """Planted prefix-bypass / .. dest must fail at move-plan time."""

    def test_dotdot_dest_refused(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            intake = tmp / "intake"
            library = tmp / "library"
            intake.mkdir()
            library.mkdir()
            src = _write_pack(intake, "Games/Pack")
            adm = _admissions(
                intake / "adm.jsonl",
                [
                    {
                        "verdict": "new",
                        "rel_pack_root": "Games/Pack",
                        "source_path": str(src),
                        "destination": "../3D-Prints-Unorg",
                    }
                ],
            )
            proc = _run(intake, library, adm, apply=False)
            self.assertNotEqual(proc.returncode, 0, proc.stderr)
            self.assertIn("dest not jailed", proc.stderr)

    def test_prefix_sibling_unorg_not_confused_with_library(self) -> None:
        """startswith('/mnt/…/3D-Prints') must not accept 3D-Prints-Unorg."""
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            prints = tmp / "3D-Prints"
            unorg = tmp / "3D-Prints-Unorg"
            prints.mkdir()
            unorg.mkdir()
            intake = unorg / "intake" / "2026-08-drive-mega"
            intake.mkdir(parents=True)
            src = _write_pack(intake, "Games/Pack")
            adm = _admissions(
                intake / "adm.jsonl",
                [
                    {
                        "verdict": "new",
                        "rel_pack_root": "Games/Pack",
                        "source_path": str(src),
                        "destination": "Games/Pack",
                    }
                ],
            )
            proc = _run(intake, prints, adm, apply=False)
            self.assertEqual(proc.returncode, 0, proc.stderr + proc.stdout)


class UnfreezeGateTests(unittest.TestCase):
    def test_apply_without_record_is_unfreeze_missing(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            intake = tmp / "intake"
            library = tmp / "library"
            intake.mkdir()
            library.mkdir()
            src = _write_pack(intake, "Games/Pack")
            adm = _admissions(
                intake / "adm.jsonl",
                [
                    {
                        "verdict": "new",
                        "rel_pack_root": "Games/Pack",
                        "source_path": str(src),
                        "destination": "Games/Pack",
                    }
                ],
            )
            proc = _run(intake, library, adm, apply=True, copy=True)
            self.assertNotEqual(proc.returncode, 0, proc.stdout)
            self.assertIn("unfreeze_missing", proc.stderr)


class ReverseManifestRollbackTests(unittest.TestCase):
    """ac-7: reverse TSV is written before the first copy; undo restores source."""

    def test_reverse_written_then_rollback_restores_fixture(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            intake = tmp / "intake"
            library = tmp / "library"
            intake.mkdir()
            library.mkdir()
            src = _write_pack(intake, "Games/Pack")
            marker = src / "m.stl"
            adm = _admissions(
                intake / "adm.jsonl",
                [
                    {
                        "verdict": "new",
                        "rel_pack_root": "Games/Pack",
                        "source_path": str(src),
                        "destination": "Games/Pack",
                    }
                ],
            )
            work = intake / ".spark-curate"
            work.mkdir()
            unfreeze = work / "unfreeze-approved-Games"
            unfreeze.write_text(
                "INIT-021/SPEC-011 fixture approval — not a live unfreeze\n",
                encoding="utf-8",
            )
            dry = _run(intake, library, adm, apply=False)
            self.assertEqual(dry.returncode, 0, dry.stderr)
            manifests = list((work / "move-manifests").glob("reverse-Games-*.tsv"))
            self.assertTrue(manifests, "reverse manifest missing after dry-run")
            self.assertTrue(marker.is_file(), "dry-run must not move")

            live = _run(intake, library, adm, apply=True, copy=True)
            self.assertEqual(live.returncode, 0, live.stderr + live.stdout)
            dest = library / "Games" / "Pack"
            self.assertTrue((dest / "m.stl").is_file())
            self.assertTrue(marker.is_file(), "--copy retains Unorg")

            latest = sorted((work / "move-manifests").glob("reverse-Games-*.tsv"))[-1]
            # Reverse TSV existed before apply (dry-run wrote one; apply wrote another).
            self.assertTrue(latest.is_file())
            undone = 0
            for line in latest.read_text(encoding="utf-8").splitlines():
                if not line.strip() or line.startswith("#"):
                    continue
                dest_s, src_s = line.split("\t", 1)
                dest_p, src_p = Path(dest_s), Path(src_s)
                if dest_p.exists():
                    if src_p.exists():
                        # --copy: dest is the extra copy — remove dest to undo.
                        if dest_p.is_dir():
                            import shutil

                            shutil.rmtree(dest_p)
                        else:
                            dest_p.unlink()
                    else:
                        dest_p.rename(src_p)
                    undone += 1
            self.assertGreaterEqual(undone, 1)
            self.assertTrue(marker.is_file())
            self.assertFalse(dest.exists())


if __name__ == "__main__":
    unittest.main()
