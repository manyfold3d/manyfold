"""Pack composition eligibility — identity is not a merge (Franken refuse).

Pure functions only. No NFS, no LLM, no I/O. Identifier-agnostic: listing
sigs and geometry hashes are just mesh-id sets. Images never enter Jaccard.

Provenance: INIT-022/SPEC-004
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from typing import FrozenSet, Iterable, Literal

# v1 numeric contract — do not invent replacements (context-plan / ADR D-2).
J_SAME = 0.90
J_COMMONS = 0.40
U_UNIQUE_MESH_REFUSE = 3
BUNDLE_MESH_COUNT = 80

CompositionVerdict = Literal[
    "same_pack",
    "subset",
    "commons",
    "bundle_vs_named",
    "presupport_variant",
    "image_only",
]

VERDICTS: FrozenSet[str] = frozenset(
    {
        "same_pack",
        "subset",
        "commons",
        "bundle_vs_named",
        "presupport_variant",
        "image_only",
    }
)
ELIGIBLE_VERDICTS: FrozenSet[str] = frozenset({"same_pack", "subset"})

# aud-1: extras whose names match support | pre-?support | lys (token / .lys, not "analysis").
_SUPPORT_RE = re.compile(
    r"(?i)(?:support|pre-?support|(?:^|[.\\/_-])lys(?:[^a-z0-9]|$))"
)

PROVENANCE = "INIT-022/SPEC-004"


@dataclass(frozen=True)
class PackSnapshot:
    """In-memory pack view for composition. No filesystem.

    ``mesh_ids`` are identifier-agnostic (listing sig or geometry hash).
    ``image_ids`` are preview/image names — they never move Jaccard (D-4).
    """

    path: str
    name: str = ""
    mesh_ids: FrozenSet[str] = frozenset()
    image_ids: FrozenSet[str] = frozenset()
    support_mesh_ids: FrozenSet[str] = frozenset()
    has_support_lattice: bool = False
    named: bool | None = None

    def __post_init__(self) -> None:
        object.__setattr__(self, "mesh_ids", frozenset(self.mesh_ids))
        object.__setattr__(self, "image_ids", frozenset(self.image_ids))
        object.__setattr__(self, "support_mesh_ids", frozenset(self.support_mesh_ids))


@dataclass(frozen=True)
class CompositionDecision:
    """Closed-enum verdict plus the metrics SPEC-005 will read."""

    verdict: CompositionVerdict
    eligible_to_merge: bool
    jaccard: float
    overlap_count: int
    unique_count_a: int
    unique_count_b: int
    keeper_path: str
    pack_a_path: str
    pack_b_path: str
    mesh_count_a: int
    mesh_count_b: int
    shared_image_count: int


def _is_named(pack: PackSnapshot) -> bool:
    if pack.named is False:
        return False
    if pack.named is True:
        return True
    return bool(pack.name.strip())


def _is_support_id(mesh_id: str) -> bool:
    return bool(_SUPPORT_RE.search(mesh_id))


def _uniques_are_supports(pack: PackSnapshot, uniques: FrozenSet[str]) -> bool:
    """True when every extra on this side is a support / lattice (aud-1)."""
    if not uniques:
        return False
    if pack.has_support_lattice:
        return True
    return all(uid in pack.support_mesh_ids or _is_support_id(uid) for uid in uniques)


def _jaccard(overlap: int, union: int) -> float:
    if union <= 0:
        return 0.0
    return overlap / union


def _keeper_path(
    verdict: CompositionVerdict,
    pack_a: PackSnapshot,
    pack_b: PackSnapshot,
    unique_a: int,
    unique_b: int,
) -> str:
    if verdict == "subset":
        return pack_b.path if unique_a == 0 else pack_a.path
    if verdict == "presupport_variant":
        # Core (non-variant) side is the one with zero uniques.
        return pack_a.path if unique_a == 0 else pack_b.path
    if verdict == "bundle_vs_named":
        count_a = len(pack_a.mesh_ids)
        count_b = len(pack_b.mesh_ids)
        if count_a >= BUNDLE_MESH_COUNT and count_b < BUNDLE_MESH_COUNT and _is_named(pack_b):
            return pack_b.path
        if count_b >= BUNDLE_MESH_COUNT and count_a < BUNDLE_MESH_COUNT and _is_named(pack_a):
            return pack_a.path
    return pack_a.path


def _classify(
    *,
    overlap: int,
    unique_a: int,
    unique_b: int,
    jaccard: float,
    count_a: int,
    count_b: int,
    pack_a: PackSnapshot,
    pack_b: PackSnapshot,
    only_a: FrozenSet[str],
    only_b: FrozenSet[str],
) -> CompositionVerdict:
    # Bundle vs named before subset: a named pack inside a dump is refuse, not attach.
    a_bundle = count_a >= BUNDLE_MESH_COUNT and count_b < BUNDLE_MESH_COUNT and _is_named(pack_b)
    b_bundle = count_b >= BUNDLE_MESH_COUNT and count_a < BUNDLE_MESH_COUNT and _is_named(pack_a)
    if a_bundle or b_bundle:
        return "bundle_vs_named"

    # same_pack: non-empty identical mesh-id sets (Jaccard ≥ J_SAME, uniques both 0).
    if overlap >= 1 and unique_a == 0 and unique_b == 0 and jaccard >= J_SAME:
        return "same_pack"

    # presupport before subset (ac-7): extras look like supports and unique ≥ 1 on the variant.
    if overlap >= 1 and unique_a == 0 and unique_b >= 1 and _uniques_are_supports(pack_b, only_b):
        return "presupport_variant"
    if overlap >= 1 and unique_b == 0 and unique_a >= 1 and _uniques_are_supports(pack_a, only_a):
        return "presupport_variant"

    # subset: one side's uniques = 0, the other has extras that are not a support lattice.
    if overlap >= 1 and unique_a == 0 and unique_b >= 1:
        return "subset"
    if overlap >= 1 and unique_b == 0 and unique_a >= 1:
        return "subset"

    # commons: Franken refuse — U≥3 each, or mid-band / high Jaccard with uniques on both sides.
    both_unique = unique_a >= 1 and unique_b >= 1
    if overlap >= 1 and unique_a >= U_UNIQUE_MESH_REFUSE and unique_b >= U_UNIQUE_MESH_REFUSE:
        return "commons"
    if both_unique and jaccard >= J_COMMONS:
        return "commons"

    # Zero mesh-id overlap: images (or absence of mesh evidence) never admit merge.
    if overlap == 0:
        return "image_only"

    # Leftover overlap that is not same_pack / subset — refuse, not same_pack (D-2 default).
    return "commons"


def decide_composition(pack_a: PackSnapshot, pack_b: PackSnapshot) -> CompositionDecision:
    """Emit one closed composition verdict. Default is refuse merge, not same_pack.

    ``eligible_to_merge`` is true only for ``same_pack`` and ``subset`` (D-3).
    """
    ids_a = frozenset(pack_a.mesh_ids)
    ids_b = frozenset(pack_b.mesh_ids)
    overlap_ids = ids_a & ids_b
    only_a = ids_a - ids_b
    only_b = ids_b - ids_a
    union = ids_a | ids_b
    overlap = len(overlap_ids)
    unique_a = len(only_a)
    unique_b = len(only_b)
    jaccard = _jaccard(overlap, len(union))
    count_a = len(ids_a)
    count_b = len(ids_b)
    shared_image_count = len(frozenset(pack_a.image_ids) & frozenset(pack_b.image_ids))

    verdict = _classify(
        overlap=overlap,
        unique_a=unique_a,
        unique_b=unique_b,
        jaccard=jaccard,
        count_a=count_a,
        count_b=count_b,
        pack_a=pack_a,
        pack_b=pack_b,
        only_a=only_a,
        only_b=only_b,
    )
    if verdict not in VERDICTS:
        raise ValueError(f"illegal composition verdict: {verdict!r}")
    eligible = verdict in ELIGIBLE_VERDICTS
    keeper = _keeper_path(verdict, pack_a, pack_b, unique_a, unique_b)
    return CompositionDecision(
        verdict=verdict,
        eligible_to_merge=eligible,
        jaccard=jaccard,
        overlap_count=overlap,
        unique_count_a=unique_a,
        unique_count_b=unique_b,
        keeper_path=keeper,
        pack_a_path=pack_a.path,
        pack_b_path=pack_b.path,
        mesh_count_a=count_a,
        mesh_count_b=count_b,
        shared_image_count=shared_image_count,
    )


def pack_snapshot(
    path: str,
    *,
    name: str = "",
    meshes: Iterable[str] = (),
    images: Iterable[str] = (),
    supports: Iterable[str] = (),
    has_support_lattice: bool = False,
    named: bool | None = None,
) -> PackSnapshot:
    """Fixture / caller helper — still pure, no I/O."""
    return PackSnapshot(
        path=path,
        name=name,
        mesh_ids=frozenset(meshes),
        image_ids=frozenset(images),
        support_mesh_ids=frozenset(supports),
        has_support_lattice=has_support_lattice,
        named=named,
    )
