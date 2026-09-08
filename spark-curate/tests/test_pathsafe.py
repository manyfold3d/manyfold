# Path safety + argv injection (INIT-021/SPEC-013).
# ac-2 / ac-3 / ac-4. Temporary trees only — never intake/Mega or the live library.
from __future__ import annotations

import io
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any

_ROOT = Path(__file__).resolve().parents[1]
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

from spark_curate.apply_moves import apply_decision
from spark_curate.config import CurateConfig
from spark_curate.decide import Decision
from spark_curate.manyfold_client import (
    SCAN_RUNNER,
    VERIFY_RUNNER,
    ManyfoldClient,
)
from spark_curate.pathsafe import (
    AbsolutePathError,
    ControlCharacterError,
    JailEscapeError,
    LeadingSlashError,
    NotCategoryModelError,
    SymlinkEscapeError,
    TraversalSegmentError,
    assert_jailed_destination,
    check_destination,
    check_rel_path,
)

# Verbatim names the Sep 4–5 run rejected (apostrophe only).
SEP4_REJECTED: list[tuple[str, str]] = [
    ("AnySTL", "King's Throne"),
    ("Games", "Dirk Statue - Dragon's Lair"),
    ("AnySTL", "Jack Daniel's Whiskey Bottle Lithophane"),
    ("AnySTL", "Painter's Delight Female Artist Scene by 3Dartman"),
    ("Games", "Tali'Zorah Full Body Figure (ArchiveSTL)"),
    ("AnySTL", "MAN Lion's Intercity Bus 2015 (Hum3D)"),
]

INJECTION_NAME = "x'\"`$(rm -rf /)\nOWNED"


def _decision(src: Path, category: str, name: str) -> Decision:
    return Decision(
        source_path=str(src),
        current_category="Old",
        current_name=src.name,
        suggested_name=name,
        category=category,
        tags=[],
        has_usable_preview=False,
        content_type="other",
        is_junk=False,
        junk_reason=None,
        confidence=1.0,
        action="move",
        notes="",
        sensitive=False,
        nudenet={},
        thumb_path=None,
    )


class AcceptSep4NamesTests(unittest.TestCase):
    """ac-2: the six real rejected names are structurally safe."""

    def test_six_verbatim_names_accepted(self) -> None:
        for category, name in SEP4_REJECTED:
            rel = f"{category}/{name}"
            with self.subTest(rel=rel):
                cat, nm = check_rel_path(rel)
                self.assertEqual(cat, category)
                self.assertEqual(nm, name)

    def test_six_names_jail_ok_on_tmp_tree(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            jail = Path(td) / "library"
            jail.mkdir()
            for category, name in SEP4_REJECTED:
                rel = f"{category}/{name}"
                dest = check_destination(rel, jail)
                self.assertTrue(dest.is_relative_to(jail.resolve()))


class RefusalTableTests(unittest.TestCase):
    """ac-3: typed error per refusal case."""

    def test_dotdot_segment(self) -> None:
        with self.assertRaises(TraversalSegmentError):
            check_rel_path("AnySTL/../etc")
        with self.assertRaises(TraversalSegmentError):
            check_rel_path("../AnySTL/Pack")
        with self.assertRaises(TraversalSegmentError):
            check_rel_path("AnySTL/foo/../../../etc")

    def test_leading_slash(self) -> None:
        with self.assertRaises(LeadingSlashError):
            check_rel_path("/AnySTL/King's Throne")

    def test_absolute_drive_path(self) -> None:
        with self.assertRaises(AbsolutePathError):
            check_rel_path(r"C:\AnySTL\King's Throne")

    def test_nul_and_control_characters(self) -> None:
        with self.assertRaises(ControlCharacterError):
            check_rel_path("AnySTL/King\x00Throne")
        with self.assertRaises(ControlCharacterError):
            check_rel_path("AnySTL/King\x07Throne")
        with self.assertRaises(ControlCharacterError):
            check_rel_path("AnySTL/King\nThrone")

    def test_symlink_resolving_outside_jail(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            outside = tmp / "outside"
            outside.mkdir()
            jail = tmp / "library"
            jail.mkdir()
            (jail / "Games").symlink_to(outside)
            with self.assertRaises(SymlinkEscapeError):
                check_destination("Games/Pack", jail)

    def test_realpath_jail_escape(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            outside = tmp / "outside" / "Pack"
            outside.mkdir(parents=True)
            jail = tmp / "library"
            jail.mkdir()
            with self.assertRaises(JailEscapeError):
                assert_jailed_destination(outside, jail)

    def test_not_category_model_depth(self) -> None:
        with self.assertRaises(NotCategoryModelError):
            check_rel_path("King's Throne")
        with self.assertRaises(NotCategoryModelError):
            check_rel_path("AnySTL/Nested/Pack")

    def test_accept_table_and_refusal_table_are_distinct(self) -> None:
        """Relaxing apostrophes must not relax traversal / jail (same file)."""
        check_rel_path("AnySTL/King's Throne")
        with self.assertRaises(TraversalSegmentError):
            check_rel_path("AnySTL/../King's Throne")
        with self.assertRaises(LeadingSlashError):
            check_rel_path("/AnySTL/King's Throne")


class EdgeNameTests(unittest.TestCase):
    def test_unicode_and_emoji(self) -> None:
        cat, name = check_rel_path("AnySTL/🐉 Throne")
        self.assertEqual(name, "🐉 Throne")
        check_rel_path("AnySTL/模型")

    def test_punctuation_only_name(self) -> None:
        cat, name = check_rel_path("AnySTL/!!!")
        self.assertEqual(name, "!!!")

    def test_255_byte_name(self) -> None:
        name = "B" * 255
        cat, got = check_rel_path(f"AnySTL/{name}")
        self.assertEqual(len(got.encode("utf-8")), 255)


class InjectionArgvTests(unittest.TestCase):
    """ac-4: quote / backtick / $(…) / newline cannot alter the executed command."""

    def test_injection_name_stays_on_stdin_json_not_argv(self) -> None:
        captured: list[tuple[list[str], bool | None, bytes | None]] = []

        def run_fn(argv: list[str], **kwargs: Any) -> subprocess.CompletedProcess[bytes]:
            stdin = kwargs.get("input")
            captured.append((list(argv), kwargs.get("shell"), stdin if isinstance(stdin, (bytes, type(None))) else None))
            return subprocess.CompletedProcess(
                argv,
                0,
                stdout=b'{"results":[],"enqueued":1}\n',
                stderr=b"",
            )

        client = ManyfoldClient(run_fn=run_fn, max_retries=1)
        rel = f"AnySTL/{INJECTION_NAME}"
        client.enqueue_scan([rel])
        client.verify_tagged([rel])
        client.apply_datapackages()

        self.assertGreaterEqual(len(captured), 3)
        for argv, shell, stdin in captured:
            self.assertIs(shell, False)
            self.assertIsInstance(argv, list)
            joined = "\0".join(argv)
            self.assertNotIn(INJECTION_NAME, joined)
            self.assertNotIn("$(rm -rf /)", joined)
            self.assertNotIn(SCAN_RUNNER.replace("require", "HACKED"), joined)

        scan_argv, _, scan_stdin = captured[0]
        self.assertIn(SCAN_RUNNER, scan_argv)
        self.assertIsNotNone(scan_stdin)
        assert scan_stdin is not None
        scan_paths = json.loads(scan_stdin.decode("utf-8"))
        self.assertEqual(scan_paths, [rel])

        verify_argv, _, verify_stdin = captured[1]
        self.assertIn(VERIFY_RUNNER, verify_argv)
        assert verify_stdin is not None
        verify_paths = json.loads(verify_stdin.decode("utf-8"))
        self.assertEqual(verify_paths, [rel])

        apply_argv, _, apply_stdin = captured[2]
        self.assertIn("manyfold:apply_datapackages", apply_argv)
        self.assertNotIn("bash", apply_argv)
        self.assertIsNone(apply_stdin)

    def test_modules_never_use_shell_true(self) -> None:
        for name in ("pathsafe.py", "manyfold_client.py", "promote.py"):
            src = (_ROOT / "spark_curate" / name).read_text(encoding="utf-8")
            self.assertNotIn("shell=True", src)
            self.assertNotIn("os.system", src)
            self.assertNotIn("shell=True", src.replace(" ", ""))


class MoverSharesPathsafeTests(unittest.TestCase):
    """Path safety is checked at move time in apply_moves."""

    def test_apply_moves_refuses_symlink_escape_at_move_time(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            outside = tmp / "outside"
            outside.mkdir()
            lib = tmp / "library"
            lib.mkdir()
            (lib / "Games").symlink_to(outside)
            src = lib / "Old" / "Pack"
            src.mkdir(parents=True)
            (src / "m.stl").write_bytes(b"x")
            cfg = CurateConfig(library_root=str(lib))
            rec = apply_decision(
                cfg,
                _decision(src, "Games", "Pack"),
                do_apply=True,
                log_fh=io.StringIO(),
            )
            self.assertFalse(rec.get("applied"))
            self.assertIn("SymlinkEscapeError", str(rec.get("error")))
            self.assertTrue(src.is_dir())
