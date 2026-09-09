# Read-only library archive_entries inverted index (INIT-021/SPEC-006).
from __future__ import annotations

import logging
from collections.abc import Iterator
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Protocol

from .archive_index import member_signature_nocrc

log = logging.getLogger(__name__)

PROVENANCE = "INIT-021/SPEC-006"

DEFAULT_PAGE_SIZE = 5000


class LibraryMembersClient(Protocol):
    def fetch_library_members_page(
        self, *, offset: int = 0, limit: int = 5000
    ) -> dict[str, Any]: ...

    def fetch_library_coverage(self) -> dict[str, Any]: ...


@dataclass(frozen=True)
class LibraryMeshPosting:
    sig: str
    model_path: str
    model_file_id: int
    digest: str | None


@dataclass
class LibraryMembersIndex:
    """Inverted basename|size → library model paths (mesh only)."""

    inverted_mesh: dict[str, list[LibraryMeshPosting]] = field(default_factory=dict)
    digest_by_model_file: dict[int, str] = field(default_factory=dict)
    mesh_sig_count: int = 0
    pages_read: int = 0
    coverage: dict[str, Any] = field(default_factory=dict)

    def models_for_sig(self, sig: str) -> list[LibraryMeshPosting]:
        return list(self.inverted_mesh.get(sig, []))

    def library_paths_for_sig(self, sig: str) -> list[str]:
        seen: set[str] = set()
        out: list[str] = []
        for post in self.inverted_mesh.get(sig, []):
            if post.model_path not in seen:
                seen.add(post.model_path)
                out.append(post.model_path)
        return sorted(out)


def _basename(pathname: str) -> str:
    return Path(pathname.replace("\\", "/")).name


def load_library_members_index(
    client: LibraryMembersClient,
    *,
    page_size: int = DEFAULT_PAGE_SIZE,
    fetch_coverage: bool = True,
) -> LibraryMembersIndex:
    """
    Page mesh archive_entries out of Postgres via rails runner — never load whole table.
    """
    index = LibraryMembersIndex()
    if fetch_coverage:
        try:
            index.coverage = client.fetch_library_coverage()
        except Exception as exc:
            log.warning("library coverage query failed: %s", exc)
            index.coverage = {"error": str(exc)}

    offset = 0
    while True:
        page = client.fetch_library_members_page(offset=offset, limit=page_size)
        index.pages_read += 1
        rows = page.get("entries")
        if not isinstance(rows, list):
            raise ValueError("library members page missing entries[]")
        if not rows:
            break
        for row in rows:
            if not isinstance(row, dict):
                continue
            pathname = row.get("pathname")
            size = row.get("size")
            model_path = row.get("model_path")
            mf_id = row.get("model_file_id")
            digest = row.get("digest")
            if (
                not isinstance(pathname, str)
                or not isinstance(model_path, str)
                or not isinstance(mf_id, int)
            ):
                continue
            try:
                size_i = int(size)
            except (TypeError, ValueError):
                continue
            base = _basename(pathname)
            if not base:
                continue
            sig = member_signature_nocrc(base, size_i)
            posting = LibraryMeshPosting(
                sig=sig,
                model_path=model_path.replace("\\", "/"),
                model_file_id=mf_id,
                digest=digest if isinstance(digest, str) and digest else None,
            )
            index.inverted_mesh.setdefault(sig, []).append(posting)
            index.mesh_sig_count += 1
            if posting.digest:
                index.digest_by_model_file[mf_id] = posting.digest
        if len(rows) < page_size:
            break
        offset += page_size

    # Deterministic posting order per sig
    for sig in index.inverted_mesh:
        index.inverted_mesh[sig] = sorted(
            index.inverted_mesh[sig],
            key=lambda p: (p.model_path.lower(), p.model_file_id),
        )
    index.inverted_mesh = dict(sorted(index.inverted_mesh.items()))
    log.info(
        "library_members loaded pages=%s mesh_rows=%s distinct_sigs=%s",
        index.pages_read,
        index.mesh_sig_count,
        len(index.inverted_mesh),
    )
    return index


def iter_library_sig_postings(
    index: LibraryMembersIndex,
) -> Iterator[tuple[str, list[LibraryMeshPosting]]]:
    for sig, postings in index.inverted_mesh.items():
        yield sig, postings
