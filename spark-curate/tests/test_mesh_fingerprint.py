# Gated mesh-fingerprint stream tests.
# Provenance: INIT-022/SPEC-003
from __future__ import annotations

import ast
import hashlib
import struct
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch

_ROOT = Path(__file__).resolve().parents[1]
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

from spark_curate.libarchive_list import _load_libarchive, list_archive_members  # noqa: E402
from spark_curate.mesh_fingerprint import (  # noqa: E402
    MAX_MEMBER_BYTES,
    MAX_RATIO,
    MegaFenceRefused,
    ResidualListRequired,
    SkipReason,
    StreamBudget,
    fingerprint_bytes,
    fingerprint_loose,
    fingerprint_paths,
    geometry_identifier_from_bytes,
    is_mega_path,
    load_cache,
    member_has_traversal,
    run_mesh_fingerprint_cli,
    stream_archive_member,
)
from spark_curate.config import CurateConfig  # noqa: E402
from spark_curate.__main__ import main  # noqa: E402


def _ascii_stl(name: str = "tri") -> bytes:
    return (
        f"solid {name}\n"
        "  facet normal 0 0 1\n"
        "    outer loop\n"
        "      vertex 0 0 0\n"
        "      vertex 1 0 0\n"
        "      vertex 0 1 0\n"
        "    endloop\n"
        "  endfacet\n"
        f"endsolid {name}\n"
    ).encode("ascii")


def _binary_stl() -> bytes:
    header = b"binary-twin" + bytes(80 - 11)
    count = struct.pack("<I", 1)
    normal = struct.pack("<fff", 0.0, 0.0, 1.0)
    v1 = struct.pack("<fff", 0.0, 0.0, 0.0)
    v2 = struct.pack("<fff", 1.0, 0.0, 0.0)
    v3 = struct.pack("<fff", 0.0, 1.0, 0.0)
    attr = struct.pack("<H", 0)
    return header + count + normal + v1 + v2 + v3 + attr


def _write_zip(path: Path, members: dict[str, bytes]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_STORED) as zf:
        for name, data in members.items():
            zf.writestr(name, data)


def _tiny_cfg(root: Path, work: Path) -> CurateConfig:
    return CurateConfig(library_root=str(root), work_dir=str(work))


class ZipVsLooseTests(unittest.TestCase):
    def test_zip_member_matches_loose_bytes_and_identifier(self) -> None:
        """ac-1: zip a.stl fingerprint equals loose a.stl (SHA + geometry)."""
        payload = _ascii_stl("a")
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            loose = tmp / "pack" / "a.stl"
            loose.parent.mkdir()
            loose.write_bytes(payload)
            zpath = tmp / "pack" / "wrap.zip"
            _write_zip(zpath, {"a.stl": payload})
            work = tmp / "work"
            work.mkdir()
            result = fingerprint_paths(
                [tmp / "pack"],
                work_dir=work,
                max_members=10,
            )
            loose_row = next(
                r for r in result.rows if r.member_path.endswith("a.stl") and r.source_path.endswith("a.stl")
            )
            zip_row = next(
                r for r in result.rows if r.member_path == "a.stl" and r.source_path.endswith(".zip")
            )
            self.assertIsNone(loose_row.skip_reason)
            self.assertIsNone(zip_row.skip_reason)
            self.assertEqual(loose_row.byte_sha256, zip_row.byte_sha256)
            self.assertEqual(loose_row.geometry_identifier, zip_row.geometry_identifier)
            self.assertEqual(loose_row.byte_sha256, hashlib.sha256(payload).hexdigest())


class AsciiBinaryTwinTests(unittest.TestCase):
    def test_ascii_and_binary_stl_share_identifier_not_sha(self) -> None:
        """ac-2: ASCII/binary STL of the same soup share geometry_identifier."""
        ascii_b = _ascii_stl("twin")
        binary_b = _binary_stl()
        self.assertNotEqual(hashlib.sha256(ascii_b).hexdigest(), hashlib.sha256(binary_b).hexdigest())
        sha_a, ident_a = fingerprint_bytes(ascii_b, "a.stl")
        sha_b, ident_b = fingerprint_bytes(binary_b, "a.stl")
        self.assertNotEqual(sha_a, sha_b)
        self.assertEqual(ident_a, ident_b)
        self.assertTrue(ident_a)


class CapAbortTests(unittest.TestCase):
    def test_member_byte_cap_no_identifier(self) -> None:
        """ac-3: MAX_MEMBER_BYTES abort → skip_reason, no identifier row."""
        payload = _ascii_stl()
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            mesh = tmp / "a.stl"
            mesh.write_bytes(payload)
            row = fingerprint_loose(
                mesh,
                budget=StreamBudget(max_stream_bytes=MAX_MEMBER_BYTES),
                cache={},
                max_member_bytes=8,
            )
            self.assertEqual(row.skip_reason, SkipReason.CAP_MEMBER_BYTES)
            self.assertIsNone(row.byte_sha256)
            self.assertIsNone(row.geometry_identifier)
            self.assertFalse(row.is_identifier_row())

    def test_stream_budget_cap_no_identifier(self) -> None:
        payload = _ascii_stl()
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            mesh = tmp / "a.stl"
            mesh.write_bytes(payload)
            row = fingerprint_loose(
                mesh,
                budget=StreamBudget(max_stream_bytes=4),
                cache={},
            )
            self.assertEqual(row.skip_reason, SkipReason.CAP_ARCHIVE_STREAM_BYTES)
            self.assertFalse(row.is_identifier_row())

    def test_ratio_cap_no_identifier(self) -> None:
        data, reason, _detail = stream_archive_member(
            "/nonexistent.zip",
            "a.stl",
            expected_size=200_000,
            compressed_size=100,
            max_ratio=MAX_RATIO,
        )
        self.assertIsNone(data)
        self.assertEqual(reason, SkipReason.CAP_RATIO)

    def test_member_count_cap(self) -> None:
        payload = _ascii_stl()
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            zpath = tmp / "many.zip"
            _write_zip(
                zpath,
                {f"m{i}.stl": payload for i in range(3)},
            )
            work = tmp / "work"
            work.mkdir()
            result = fingerprint_paths(
                [zpath],
                work_dir=work,
                max_members=1,
            )
            count_skips = [r for r in result.rows if r.skip_reason == SkipReason.CAP_MEMBER_COUNT]
            self.assertTrue(count_skips)
            self.assertTrue(all(r.geometry_identifier is None for r in count_skips))


class ListingUnchangedTests(unittest.TestCase):
    def test_list_archive_members_still_does_not_read_data(self) -> None:
        """ac-4: listing-only path unchanged — archive_read_data must not run."""
        payload = _ascii_stl()
        with tempfile.TemporaryDirectory() as td:
            zpath = Path(td) / "a.zip"
            _write_zip(zpath, {"a.stl": payload})
            try:
                lib = _load_libarchive()
            except Exception as exc:
                self.skipTest(f"libarchive not installed on this host: {exc}")
            original = lib.archive_read_data

            def _boom(*_a, **_k):
                raise AssertionError("archive_read_data must not be called on listing path")

            lib.archive_read_data = _boom  # type: ignore[method-assign]
            try:
                listing = list_archive_members(zpath)
                self.assertGreaterEqual(len(listing.members), 1)
                self.assertEqual(listing.members[0].basename, "a.stl")
            finally:
                lib.archive_read_data = original  # type: ignore[method-assign]


class IncrementalCacheTests(unittest.TestCase):
    def test_same_mtime_size_reuses_jsonl_without_reparse(self) -> None:
        """ac-5: same mtime+size → reuse JSONL row; no re-parse."""
        payload = _ascii_stl()
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            mesh = tmp / "a.stl"
            mesh.write_bytes(payload)
            work = tmp / "work"
            work.mkdir()
            first = fingerprint_paths([mesh], work_dir=work)
            self.assertEqual(first.identified, 1)
            self.assertEqual(first.reused, 0)
            with patch(
                "spark_curate.mesh_fingerprint.geometry_identifier_from_bytes",
                side_effect=AssertionError("re-parse must not run"),
            ):
                second = fingerprint_paths([mesh], work_dir=work)
            self.assertEqual(second.reused, 1)
            self.assertEqual(second.rows[0].geometry_identifier, first.rows[0].geometry_identifier)
            cache = load_cache(Path(first.cache_path))
            self.assertEqual(len(cache), 1)


class SkipAndErrorTests(unittest.TestCase):
    def test_skip_slicer_extensions(self) -> None:
        """ac-6: skip .gcode .ctb .lys .chitubox .step."""
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            work = tmp / "work"
            work.mkdir()
            files = []
            for ext in (".gcode", ".ctb", ".lys", ".chitubox", ".step"):
                p = tmp / f"toolpath{ext}"
                p.write_bytes(b"G1 X0\n")
                files.append(p)
            result = fingerprint_paths(files, work_dir=work)
            self.assertTrue(result.rows)
            self.assertTrue(all(r.skip_reason == SkipReason.SKIP_EXTENSION for r in result.rows))
            self.assertTrue(all(not r.is_identifier_row() for r in result.rows))

    def test_unreadable_mesh_is_fingerprint_error_not_fake_hash(self) -> None:
        """ac-6: garbage mesh → fingerprint_error, never a fake hash."""
        with self.assertRaises(Exception):
            geometry_identifier_from_bytes(b"not-a-mesh", "junk.stl")
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            junk = tmp / "junk.stl"
            junk.write_bytes(b"not-a-mesh-at-all")
            work = tmp / "work"
            work.mkdir()
            result = fingerprint_paths([junk], work_dir=work)
            self.assertEqual(result.rows[0].skip_reason, SkipReason.FINGERPRINT_ERROR)
            self.assertIsNone(result.rows[0].byte_sha256)
            self.assertIsNone(result.rows[0].geometry_identifier)

    def test_empty_mesh_is_fingerprint_error(self) -> None:
        empty = (
            b"solid empty\nendsolid empty\n"
        )
        with self.assertRaises(Exception):
            fingerprint_bytes(empty, "empty.stl")


class MegaFenceTests(unittest.TestCase):
    def test_cli_refuses_mega_root_by_default(self) -> None:
        """ac-7: Mega root stays refused unless existing fence allows."""
        self.assertTrue(is_mega_path("/mnt/backups/3D-Prints-Unorg/intake/Mega"))
        self.assertTrue(is_mega_path("/mnt/backups/3D-Prints-Unorg/intake/Mega/Anime"))
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            residual = tmp / "residual.txt"
            residual.write_text("/mnt/backups/3D-Prints-Unorg/intake/Mega/Pack\n", encoding="utf-8")
            rc = main(
                [
                    "--mode",
                    "mesh-fingerprint",
                    "--library",
                    "/mnt/backups/3D-Prints-Unorg/intake/Mega",
                    "--residual-list",
                    str(residual),
                    "--work-dir",
                    str(tmp / "work"),
                ]
            )
            self.assertEqual(rc, 2)

    def test_allow_live_is_the_existing_lift(self) -> None:
        self.assertTrue(is_mega_path("/mnt/backups/3D-Prints-Unorg/intake/Mega"))
        # Existing SPEC-010 --allow-live is the only lift; default stays refused.
        with self.assertRaises(MegaFenceRefused):
            from spark_curate.mesh_fingerprint import assert_mega_fence_allows

            assert_mega_fence_allows(
                "/mnt/backups/3D-Prints-Unorg/intake/Mega", allow_live=False
            )
        from spark_curate.mesh_fingerprint import assert_mega_fence_allows

        assert_mega_fence_allows(
            "/mnt/backups/3D-Prints-Unorg/intake/Mega", allow_live=True
        )


class SecurityAndCliTests(unittest.TestCase):
    def test_path_traversal_member_skipped(self) -> None:
        self.assertTrue(member_has_traversal("../evil.stl"))
        self.assertTrue(member_has_traversal("/abs/evil.stl"))
        self.assertFalse(member_has_traversal("files/hero.stl"))
        data, reason, _ = stream_archive_member(
            "/tmp/x.zip", "../evil.stl", expected_size=10
        )
        self.assertIsNone(data)
        self.assertEqual(reason, SkipReason.PATH_TRAVERSAL)

    def test_residual_list_required(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            cfg = _tiny_cfg(Path(td), Path(td) / "work")
            ns = type("NS", (), {"residual_list": None, "library_candidates": None, "allow_live": False})()
            with self.assertRaises(ResidualListRequired):
                run_mesh_fingerprint_cli(ns, cfg)

    def test_list_archive_members_source_has_no_read_data_call(self) -> None:
        tree = ast.parse(
            (Path(__file__).resolve().parents[1] / "spark_curate" / "libarchive_list.py").read_text(
                encoding="utf-8"
            )
        )
        listing_fn = next(
            n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == "list_archive_members"
        )
        called = [
            node.attr
            for node in ast.walk(listing_fn)
            if isinstance(node, ast.Attribute)
        ]
        self.assertNotIn("archive_read_data", called)
        self.assertNotIn("archive_read_extract", called)

    def test_no_extract_onto_input_tree(self) -> None:
        payload = _ascii_stl()
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            pack = tmp / "library_like"
            pack.mkdir()
            mesh = pack / "a.stl"
            mesh.write_bytes(payload)
            work = tmp / "work"
            work.mkdir()
            fingerprint_paths([pack], work_dir=work)
            leftovers = [p for p in pack.rglob("*") if p != mesh and p.is_file()]
            self.assertEqual(leftovers, [])


if __name__ == "__main__":
    unittest.main()
