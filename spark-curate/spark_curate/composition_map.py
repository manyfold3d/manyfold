"""Map identity + composition into the existing INIT-018 judge / INIT-021 admit.

Does not edit ``decide_merge.py``. Same boundary pattern as
``archive_member_overlap_nocrc`` (INIT-021): keep provenance visible, emit
only the signal shape the judge already parses, and refuse Franken attach
before the judge can treat listing STRONG as eligibility.

Provenance: INIT-022/SPEC-005
"""
from __future__ import annotations

from typing import Sequence

from .candidates import DEFAULT_MESH_OVERLAP_T
from .composition import ELIGIBLE_VERDICTS, U_UNIQUE_MESH_REFUSE, VERDICTS

PROVENANCE = "INIT-022/SPEC-005"

GEOMETRY_TWIN = "geometry_twin"
GEOMETRY_NEAR_PREFIX = "geometry_near:"
MESH_BYTE_DIGEST = "mesh_byte_digest"
MESH_BYTE_DIGEST_PREFIX = "mesh_byte_digest:"
COMPOSITION_PREFIX = "composition:"
UNIQUE_INTAKE_PREFIX = "unique_meshes_intake:"
UNIQUE_A_PREFIX = "unique_meshes_a:"

NOCRC_PREFIX = "archive_member_overlap_nocrc:"
OVERLAP_PREFIX = "archive_member_overlap:"
PROVENANCE_NOCRC = "overlap_provenance:nocrc"

REFUSE_VERDICTS = frozenset(
    {"commons", "bundle_vs_named", "presupport_variant", "image_only"}
)

# Signals the INIT-018 judge treats as structural / STRONG / UNCERTAIN admit.
_JUDGE_ADMIT_PREFIXES = (
    OVERLAP_PREFIX,
    "shared_digest:",
    "basename_size_overlap",
)
_JUDGE_ADMIT_EXACT = frozenset(
    {
        "name_near_dupe",
        "shared_digest",
        "shared_archive_member",
        "exact_file_digest",
    }
)


def parse_composition_verdict(signals: Sequence[str]) -> str | None:
    """Return the closed composition verdict from ``composition:<verdict>``, or None."""
    for s in signals:
        if s.startswith(COMPOSITION_PREFIX):
            raw = s.split(":", 1)[1].strip()
            if raw in VERDICTS:
                return raw
            return None
    return None


def composition_is_eligible(verdict: str | None) -> bool:
    return verdict is not None and verdict in ELIGIBLE_VERDICTS


def composition_is_refuse(signals: Sequence[str]) -> bool:
    verdict = parse_composition_verdict(signals)
    return verdict is not None and verdict in REFUSE_VERDICTS


def has_geometry_identity(signals: Sequence[str]) -> bool:
    return GEOMETRY_TWIN in signals or any(
        s.startswith(GEOMETRY_NEAR_PREFIX) for s in signals
    )


def geometry_near_dist(signals: Sequence[str]) -> float | None:
    for s in signals:
        if s.startswith(GEOMETRY_NEAR_PREFIX):
            try:
                return float(s.split(":", 1)[1])
            except ValueError:
                return None
    return None


def mesh_byte_digest_count(signals: Sequence[str]) -> int:
    """Distinct ``mesh_byte_digest`` files. Bare token counts as 1."""
    for s in signals:
        if s.startswith(MESH_BYTE_DIGEST_PREFIX):
            try:
                return int(s.split(":", 1)[1])
            except ValueError:
                return 0
    if MESH_BYTE_DIGEST in signals:
        return 1
    return 0


def unique_meshes_intake(signals: Sequence[str]) -> int | None:
    for prefix in (UNIQUE_INTAKE_PREFIX, UNIQUE_A_PREFIX):
        for s in signals:
            if s.startswith(prefix):
                try:
                    return int(s.split(":", 1)[1])
                except ValueError:
                    return None
    return None


def _is_judge_admit_trigger(signal: str) -> bool:
    if signal in _JUDGE_ADMIT_EXACT:
        return True
    return any(signal.startswith(p) for p in _JUDGE_ADMIT_PREFIXES)


def _withhold_judge_admit(signals: list[str]) -> list[str]:
    """Drop judge-facing admit triggers; keep identity / composition / nocrc provenance."""
    return [s for s in signals if not _is_judge_admit_trigger(s)]


def map_signals_for_judge(
    signals: Sequence[str],
    *,
    mesh_t: int = DEFAULT_MESH_OVERLAP_T,
) -> list[str]:
    """Map geometry + composition (+ nocrc) into the existing judge signal shape.

    Keeps ``geometry_twin``, ``geometry_near:<dist>``, ``mesh_byte_digest``,
    ``composition:<verdict>``, and ``_nocrc`` provenance visible (ac-1).

    ``same_pack`` / ``subset`` + twin → STRONG overlap the judge already parses.
    ``geometry_near`` (not twin) → UNCERTAIN (``name_near_dupe``).
    Refuse / incomplete composition → withhold STRONG/UNCERTAIN admit triggers
    so the judge stays REFUSE (Franken). Listing-only (no geometry) still maps
    nocrc → overlap as INIT-021.
    """
    out = list(signals)
    nocrc_ns: list[str] = []
    for s in signals:
        if s.startswith(NOCRC_PREFIX):
            nocrc_ns.append(s.split(":", 1)[1])

    if nocrc_ns and PROVENANCE_NOCRC not in out:
        out.append(PROVENANCE_NOCRC)

    verdict = parse_composition_verdict(out)
    has_twin = GEOMETRY_TWIN in out
    has_near = any(s.startswith(GEOMETRY_NEAR_PREFIX) for s in out)
    has_geometry = has_twin or has_near
    incomplete = has_geometry and verdict is None
    refuse = verdict is not None and verdict in REFUSE_VERDICTS

    if incomplete or refuse:
        return _withhold_judge_admit(out)

    for n in nocrc_ns:
        mapped = f"{OVERLAP_PREFIX}{n}"
        if mapped not in out:
            out.append(mapped)

    if composition_is_eligible(verdict):
        digest_n = mesh_byte_digest_count(out)
        if has_twin:
            strong = f"{OVERLAP_PREFIX}{mesh_t}"
            if strong not in out:
                out.append(strong)
        elif digest_n >= 2:
            sd = f"shared_digest:{digest_n}"
            if sd not in out:
                out.append(sd)
        elif has_near and "name_near_dupe" not in out:
            out.append("name_near_dupe")

    return out


def intake_admit_from_composition(
    signals: Sequence[str],
    *,
    dest_collision: bool = False,
) -> tuple[str, str | None, str | None] | None:
    """Intake ``new|hold`` override from composition. None → fall through to listing path.

    Never returns ``attach``. Commons with unique intake meshes ≥
    ``U_UNIQUE_MESH_REFUSE`` is ``new`` (aud-2). Incomplete geometry holds.
    """
    verdict = parse_composition_verdict(signals)
    if has_geometry_identity(signals) and verdict is None:
        return "hold", "composition_refuse", "REFUSE"
    if verdict is None:
        return None
    if verdict in ELIGIBLE_VERDICTS:
        return None
    if dest_collision:
        return "hold", "name_collision", "REFUSE"
    if verdict == "commons":
        unique = unique_meshes_intake(signals)
        if unique is not None and unique >= U_UNIQUE_MESH_REFUSE:
            return "new", None, "REFUSE"
        return "hold", "composition_refuse", "REFUSE"
    # bundle_vs_named / presupport_variant / image_only — never attach
    return "new", None, "REFUSE"


def library_may_plan_merge(signals: Sequence[str]) -> bool:
    """True only when composition is ``same_pack`` / ``subset`` (D-3)."""
    return composition_is_eligible(parse_composition_verdict(signals))
