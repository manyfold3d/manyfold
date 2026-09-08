# Cross-root archive recall tests — INIT-021/SPEC-006
from __future__ import annotations

import json
import os
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import MagicMock, patch

_ROOT = Path(__file__).resolve().parents[1]
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

from spark_curate import libarchive_list as libarchive_list_mod  # noqa: E402
from spark_curate.archive_index import (  # noqa: E402
    CROSS_ROOT_INDEX_PREFIX,
    CROSS_ROOT_CANDIDATES_PREFIX,
    BatchPackRef,
    list_batch_archive,
    member_signature_nocrc,
    run_cross_root_archive_recall,
)
from spark_curate.candidates import MergeCandidate, build_cross_root_candidates  # noqa: E402
from spark_curate.embed_clients import ImageEmbedClient  # noqa: E402
from spark_curate.indexable import group_multipart_volumes  # noqa: E402
from spark_curate.library_members import (  # noqa: E402
    LibraryMembersIndex,
    LibraryMeshPosting,
)
from spark_curate.manyfold_client import ManyfoldClient  # noqa: E402

_LIBARCHIVE = os.environ.get(
    "SPARK_CURATE_LIBARCHIVE",
    "/tmp/libarchive-extract/usr/lib/x86_64-linux-gnu/libarchive.so.13",
)
_INTAKE_ROOT = Path("/mnt/backups/3D-Prints-Unorg/intake/2026-08-drive-mega")
_SAMPLE_RAR = _INTAKE_ROOT / (
    "04-gdrive-17sL1SxU-wuqGgrFyr1esOTZAyvpZGlmi/LINEAL 3DXM ART/"
    "3DXM - Abomination Chibi/3DXM - Abomination Chibi.rar"
)
_SAMPLE_7Z = _INTAKE_ROOT / (
    "04-gdrive-17sL1SxU-wuqGgrFyr1esOTZAyvpZGlmi/LINEAL Adults/"
    "CARNAGE  preystudio/CARNAGE  preystudio.7z"
)


def _write_zip(path: Path, members: dict[str, bytes]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_STORED) as zf:
        for name, data in members.items():
            zf.writestr(name, data)


def _libarchive_available() -> bool:
    return Path(_LIBARCHIVE).is_file()


@unittest.skipUnless(_libarchive_available(), "libarchive.so not available")
class LibarchiveFormatTests(unittest.TestCase):
    def test_zip_rar_7z_all_listed(self) -> None:
        """ac-2: zip, rar, and 7z yield members via libarchive (not zipfile-only)."""
        from spark_curate.libarchive_list import list_archive_members

        with tempfile.TemporaryDirectory() as tmp:
            zpath = Path(tmp) / "fixture.zip"
            _write_zip(zpath, {"hero.stl": b"solid z\n"})
            z_list = list_archive_members(zpath, lib_path=_LIBARCHIVE)
            self.assertIsNone(z_list.skip_reason)
            self.assertTrue(any(m.basename == "hero.stl" for m in z_list.members))

        if not _SAMPLE_RAR.is_file():
            self.skipTest("intake rar fixture not mounted")
        r_list = list_archive_members(_SAMPLE_RAR, lib_path=_LIBARCHIVE, max_members=50)
        self.assertIsNone(r_list.skip_reason, r_list.skip_detail)
        mesh = [m for m in r_list.members if m.basename.endswith(".stl")]
        self.assertGreater(len(mesh), 0, "rar must list mesh members zipfile cannot read")

        if not _SAMPLE_7Z.is_file():
            self.skipTest("intake 7z fixture not mounted")
        z7_list = list_archive_members(_SAMPLE_7Z, lib_path=_LIBARCHIVE, max_members=50)
        self.assertIsNone(z7_list.skip_reason, z7_list.skip_detail)
        self.assertGreater(len(z7_list.members), 0)

    def test_zipfile_blind_to_rar(self) -> None:
        """Prove zip-only reader cannot open rar (libarchive can)."""
        if not _SAMPLE_RAR.is_file():
            self.skipTest("intake rar fixture not mounted")
        with self.assertRaises(zipfile.BadZipFile):
            with zipfile.ZipFile(_SAMPLE_RAR, "r"):
                pass


class NoExtractTests(unittest.TestCase):
    @unittest.skipUnless(_libarchive_available(), "libarchive.so not available")
    def test_archive_read_data_never_called(self) -> None:
        """ac-5: extract path must not run — patched archive_read_data raises."""
        from spark_curate.libarchive_list import _load_libarchive, list_archive_members

        lib = _load_libarchive(_LIBARCHIVE)
        original = lib.archive_read_data

        def _boom(*args, **kwargs):  # noqa: ANN002, ANN003
            raise AssertionError("archive_read_data must not be called on listing path")

        lib.archive_read_data = _boom  # type: ignore[method-assign]
        try:
            with tempfile.TemporaryDirectory() as tmp:
                zpath = Path(tmp) / "t.zip"
                _write_zip(zpath, {"a.stl": b"x", "b.stl": b"y"})
                listing = list_archive_members(zpath, lib_path=_LIBARCHIVE)
                self.assertIsNone(listing.skip_reason)
                self.assertGreaterEqual(len(listing.members), 1)
        finally:
            lib.archive_read_data = original  # type: ignore[method-assign]


class MultipartTests(unittest.TestCase):
    def test_seven_part_set_one_candidate_path(self) -> None:
        """ac-3: multi-part rar grouped; listed from first volume."""
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp) / "Protectron"
            parts = []
            for i in range(1, 8):
                p = base / f"Protectron.part{i:02d}.rar"
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_bytes(b"not-real-rar-header")
                parts.append(p)
            mp_sets, standalone = group_multipart_volumes(parts)
            self.assertEqual(len(mp_sets), 1)
            self.assertEqual(len(standalone), 0)
            self.assertEqual(mp_sets[0].first_volume_path.name, "Protectron.part01.rar")
            self.assertEqual(len(mp_sets[0].all_part_paths), 7)

    def test_missing_middle_volume_flagged(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp) / "Set"
            files = [
                base / "Set.part01.rar",
                base / "Set.part02.rar",
                base / "Set.part04.rar",
            ]
            for f in files:
                f.parent.mkdir(parents=True, exist_ok=True)
                f.write_bytes(b"x")
            mp_sets, _ = group_multipart_volumes(files)
            self.assertEqual(len(mp_sets), 1)
            self.assertEqual(mp_sets[0].missing_middle_volume(), 3)


class CacheHitTests(unittest.TestCase):
    @unittest.skipUnless(_libarchive_available(), "libarchive.so not available")
    def test_second_run_cache_hit(self) -> None:
        """ac-6: unchanged archive mtime+size → zero re-opens (cache hit counter)."""
        os.environ["SPARK_CURATE_LIBARCHIVE"] = _LIBARCHIVE
        with tempfile.TemporaryDirectory() as tmp:
            work = Path(tmp) / ".spark-curate"
            zpath = Path(tmp) / "pack" / "data.zip"
            _write_zip(zpath, {"mesh.stl": b"solid\n"})
            pack = BatchPackRef(
                pack_root=zpath.parent,
                rel_posix="pack",
                archive_paths=(str(zpath),),
            )
            stats: dict[str, int] = {}
            first = list_batch_archive(
                zpath, pack=pack, cache_dir=work, cache_stats=stats
            )
            self.assertFalse(first.cache_hit)
            second = list_batch_archive(
                zpath, pack=pack, cache_dir=work, cache_stats=stats
            )
            self.assertTrue(second.cache_hit)
            self.assertEqual(stats.get("hits"), 1)


class CandidateSignalTests(unittest.TestCase):
    def test_cross_root_nocrc_signal_name(self) -> None:
        """ac-4: cross-root overlap uses archive_member_overlap_nocrc:N."""
        from spark_curate.archive_index import BatchArchiveListing, MemberSig

        sig = member_signature_nocrc("Hero.stl", 12345)
        lib = LibraryMembersIndex(
            inverted_mesh={
                sig: [
                    LibraryMeshPosting(
                        sig=sig,
                        model_path="DC/Batman",
                        model_file_id=1,
                        digest=None,
                    )
                ]
            }
        )
        pack = BatchPackRef(
            pack_root=Path("/batch/p1"),
            rel_posix="Anime/Hero",
            archive_paths=("/batch/p1/hero.zip",),
        )
        member = MemberSig(
            basename="Hero.stl",
            uncompressed_size=12345,
            crc32=999,
            is_mesh=True,
            member_path="Hero.stl",
        )
        bl = BatchArchiveListing(pack=pack, listing_path="/batch/p1/hero.zip", members=[member])
        cands = build_cross_root_candidates(
            batch_listings=[bl],
            library_index=lib,
            batch_root=Path("/batch"),
        )
        self.assertEqual(len(cands), 1)
        overlap = [s for s in cands[0].signals if s.startswith("archive_member_overlap_nocrc:")]
        self.assertEqual(overlap, ["archive_member_overlap_nocrc:1"])
        self.assertIn("origin_pair:intake_library", cands[0].signals)

    def test_digest_unavailable_not_miss(self) -> None:
        """ac-11: missing library digest → digest_unavailable, not treated as miss."""
        from spark_curate.archive_index import BatchArchiveListing, MemberSig

        sig = member_signature_nocrc("X.stl", 100)
        lib = LibraryMembersIndex(
            inverted_mesh={
                sig: [
                    LibraryMeshPosting(
                        sig=sig,
                        model_path="G/X",
                        model_file_id=9,
                        digest=None,
                    )
                ]
            }
        )
        pack = BatchPackRef(
            pack_root=Path("/b/p"),
            rel_posix="G/X",
            archive_paths=("/b/p/a.zip",),
        )
        bl = BatchArchiveListing(
            pack=pack,
            listing_path="/b/p/a.zip",
            members=[
                MemberSig("X.stl", 100, 0, True, "X.stl"),
            ],
        )
        cands = build_cross_root_candidates(
            batch_listings=[bl],
            library_index=lib,
            batch_root=Path("/b"),
        )
        self.assertIn("digest_unavailable", cands[0].signals)
        self.assertNotIn("digest_miss", cands[0].signals)


class ArtifactPrefixTests(unittest.TestCase):
    def test_batch_artifacts_distinct_prefix(self) -> None:
        """ac-8: artifacts under batch .spark-curate with cross-root prefix."""
        lib = LibraryMembersIndex(inverted_mesh={})
        with tempfile.TemporaryDirectory() as tmp:
            batch = Path(tmp) / "batch"
            work = batch / ".spark-curate"
            batch.mkdir()
            result = run_cross_root_archive_recall(
                batch_root=batch,
                work_dir=work,
                library_index=lib,
                run_id="test",
            )
            self.assertTrue(result.batch_index_path)
            self.assertIn(CROSS_ROOT_INDEX_PREFIX, result.batch_index_path or "")
            self.assertIn(CROSS_ROOT_CANDIDATES_PREFIX, result.candidates_path or "")
            self.assertTrue(str(work) in (result.batch_index_path or ""))


class NoScanJobTests(unittest.TestCase):
    def test_library_load_never_enqueues_scan(self) -> None:
        """ac-1: no Scan:: job triggered during library read."""
        client = ManyfoldClient(run_fn=MagicMock())
        with patch.object(client, "fetch_library_members_page", return_value={"entries": []}):
            with patch.object(
                client,
                "fetch_library_coverage",
                return_value={"library_archives_unindexed": 4073},
            ):
                with patch.object(client, "enqueue_scan", side_effect=AssertionError("scan")):
                    from spark_curate.library_members import load_library_members_index

                    load_library_members_index(client, page_size=100)


class NoImageEmbedTests(unittest.TestCase):
    def test_image_embed_client_never_constructed_on_recall(self) -> None:
        """ac-13: image-embed client is never constructed on match path."""
        constructed: list[object] = []
        original_init = ImageEmbedClient.__init__

        def _track(self, cfg):  # noqa: ANN001
            constructed.append(self)
            original_init(self, cfg)

        lib = LibraryMembersIndex(inverted_mesh={})
        with patch.object(ImageEmbedClient, "__init__", _track):
            with tempfile.TemporaryDirectory() as tmp:
                run_cross_root_archive_recall(
                    batch_root=Path(tmp) / "batch",
                    work_dir=Path(tmp) / "batch" / ".spark-curate",
                    library_index=lib,
                )
        self.assertEqual(constructed, [])


class JunkExclusionTests(unittest.TestCase):
    @unittest.skipUnless(_libarchive_available(), "libarchive.so not available")
    def test_macosx_excluded_from_listing(self) -> None:
        from spark_curate.libarchive_list import list_archive_members

        with tempfile.TemporaryDirectory() as tmp:
            zpath = Path(tmp) / "j.zip"
            _write_zip(
                zpath,
                {
                    "good.stl": b"a",
                    "__MACOSX/._good.stl": b"junk",
                    "readme.txt": b"hi",
                },
            )
            listing = list_archive_members(zpath, lib_path=_LIBARCHIVE)
            names = {m.basename for m in listing.members}
            self.assertIn("good.stl", names)
            self.assertNotIn("._good.stl", names)


if __name__ == "__main__":
    unittest.main()
