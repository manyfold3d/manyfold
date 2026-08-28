# ADR 0002: Merge HTTP off uniqueness Redlock

**Status:** Accepted  
**Date:** 2026-08-27  
**Provenance:** `INIT-002/SPEC-001`  
**source:** `RCA-002`  
**Also cites:** `BRAIN-001`

---

## Context

Interactive merge / problem-resolve HTTP must succeed or fail on the merge itself: Postgres
commit plus in-request file adopt. Live failure class `manyfold-merge-resolve-redlock-500`
(RCA-002): `Model::Merge` enqueued a unique scan job after the inner merge transaction but
**inside** `Problem.resolve_batch`’s outer write transaction. ActiveJob uniqueness acquired a
Redlock against Redis; a Redis blip raised into Puma (HTTP 500) and rolled the outer
transaction back. The intended skip (`Current.set(skip_problem_checks: true)`) is a no-op:
`Model#suppress_problem_checks?` reads only record flags. Nesting resolve returned
`{removed: true}` without destroying the Problem row, so a rolled-back merge left the problem
in place.

Without a binding contract, later authors re-read `Current` in `Model`, fail-open uniqueness
globally, or add a Redis PVC as the “fix.” This ADR records BRAIN-001 **P2** so SPEC-002 /
SPEC-003 / SPEC-004 implement it; they do not renegotiate the owner.

## Decision

**Merge HTTP success is a function of DB + file adopt only.** Interactive merge / resolve
requests must **not** acquire ActiveJob uniqueness Redlock.

1. **No unique enqueue on merge HTTP.** `Model::Merge` does not call
   `check_for_problems_later` (or any other `unique` `perform_later`) on the request path.
   No unique job while a write transaction is open — including inefficient convert enqueue
   inside `resolve_batch`. Follow-up full re-scan is existing scan / Phase B jobs, not the
   merge response. HTTP 200 does not require a uniqueness lock to succeed.
2. **Skip owner is `ScanContext` / record flags.** Stamp `ScanContext.apply!` on `@target`,
   sources, and their files (same pattern as Unmerge / create-from-path). Production skip is
   `skip_problem_check` / `suppress_problem_checks` on the record. **Do not** add a
   `Current.skip_problem_checks` read in `Model` (`suppress_problem_checks?` stays flags-only).
   `Current.set` may remain for observers; it is not the skip that protects merge HTTP.
3. **Both HTTP surfaces are in scope:**
   - `ProblemsController#resolve` — Nesting merge (`Problems::Nesting#resolve!` →
     `problem.problematic.merge!` inside `Problem.resolve_batch`)
   - `ModelsController#merge` — `Model#merge!` / `Model::Merge` (no Current skip today; flags
     on Merge cover it)
4. **Destroy the Nesting Problem row** on successful merge, in the same transaction, equivalent
   to `create_or_clear` false. Do not leave `resolving` or lie with `{removed: true}` while the
   row still exists.
5. **Defer NFS `reattach!` / `{move: true}`** until after the outermost commit, still
   in-request (BRAIN-001 P2). Opposite split (DB new, disk old) is recoverable; today’s split
   (disk new, DB old) is not. SPEC-003 implements this; SPEC-002 must not claim the class
   closed without it.
6. **GitOps does not own this class.** Redis anti-evict + tcp readiness and the fork image pin
   live in SPEC-004. Keep emptyDir; **no Redis PVC** as the close for this failure class.
   Ephemeral queues are accepted; scans rebuild them. Pin only the operator fork digest that
   contains SPEC-002+003 — never upstream. SPEC-004 MUST NOT claim RCA-002 is closed by Redis
   YAML alone.

Spark `ApplySparkMergePlanJob` inherits flag-stamping; HTTP acceptance does not require it.

### Ownership (fixed)

| Concern | Owner |
|---------|--------|
| Skip flags + no unique enqueue + destroy Nesting row | SPEC-002 (`Model::Merge`, `Problem.resolve_batch`, `ModelsController::Merge`) |
| NFS adopt after outermost commit | SPEC-003 |
| Redis hygiene + fork image pin | SPEC-004 (does not close RCA-002) |
| Invariant contract | this ADR |

## Consequences

- Merge / resolve HTTP 200 means the merge persisted (`MergeHistory` exists, sources gone) and,
  for Nesting, the Problem row is destroyed — even if Redis uniqueness is down.
- Authors do not re-open `Current` reads in `Model`, globally fail-open uniqueness, or treat a
  Redis PVC as the merge-500 fix.
- Deploy of the app-layer fix requires a new pinned fork image (SPEC-004). Redis YAML changes
  damp descheduler bounce; they are not sufficient-alone.
- Related: interactive **model update** is the same uniqueness-Redlock HTTP class on a
  different surface — see ADR 0004 (`INIT-005`). Merge/resolve ownership in this ADR is
  unchanged.

## Rejected approaches

| Do not | Why |
|--------|-----|
| Swallow / rescue the 500 in `ProblemsController` (or merge controller) | Outer transaction still rolls back; user sees failure or a lie (GR-001) |
| Background / async the merge off the HTTP request | Merge stays synchronous in-request (GR-002); HTTP 200 must mean files moved (SPEC-003) |
| Disable ActiveJob uniqueness globally, or set global `on_redis_connection_error` off `:raise` | Wrong owner; uniqueness remains valid for scan jobs (REQ-007). Optional **per-job** non-raise on `CheckForProblemsJob` only is belt-and-suspenders, never the owner |
| Redis PVC / Recreate / node pin / limit bump as the class close | New Multi-Attach class; does not stop enqueue-on-request (REQ-008). PVC is a future queue-durability initiative |
| Edit RCA-001 probe / health / liveness handlers | Different failure class (GR-003) |
| Phrase special-case “if nesting, skip job” | Same class returns on any resolve that hits unique `perform_later` |
| Client retry / “click merge again” as the fix | Compensates for a server invariant; disk may already have moved |

## Forbidden

| Do not | Why |
|--------|-----|
| Acquire uniqueness Redlock on interactive merge/resolve HTTP | RCA-002 class: Redis blip 500s and rolls back a completed inner merge |
| New `Current.skip_problem_checks` (or `Current.*`) read in `Model` | `ScanContext` / record flags already killed that pattern (`model.rb` comment) |
| Leave Nesting Problem rows `resolving` after a merge that stuck | UI `{removed: true}` without destroy is a lie; default_scope can resurrect |
| Unique `perform_later` inside an open write transaction on this HTTP path | Redlock raise aborts the request and rolls SQL |
| Claim Redis GitOps closed RCA-002 | App-layer ownership; SPEC-004 is hygiene + pin only |

## References

- `source: RCA-002` — `sdd/rca/RCA-002-manyfold-merge-resolve-redlock-500/`
- `BRAIN-001` — `sdd/brainstorms/BRAIN-001-manyfold-merge-resolve-redlock/decision-document.md` (P2)
- Initiative: `INIT-002-manyfold-merge-http-off-redlock`
- Implements: SPEC-002 (flags / no unique enqueue / destroy row), SPEC-003 (defer `reattach!`),
  SPEC-004 (Redis anti-evict + readiness + fork pin; no PVC)
- Related: `docs/adr/0004-model-update-http-off-redlock-raise.md` (`INIT-005`) — model-update HTTP

---

Provenance: `INIT-002/SPEC-001`
