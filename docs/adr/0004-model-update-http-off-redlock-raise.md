# ADR 0004: Model-update HTTP off uniqueness Redlock raise

**Status:** Accepted  
**Date:** 2026-08-28  
**Provenance:** `INIT-005/SPEC-001`  
**source:** live `ModelsController#update` HTTP 500 (2026-08-28)  
**Also cites:** `ASMT-003`, `RCA-002`, ADR 0002

---

## Context

ADR 0002 closed **merge / resolve** HTTP vs uniqueness Redlock (RCA-002). Interactive **model
update** was left on the unique-enqueue path.

Live failure (2026-08-28): `ModelsController#update` persisted the row, then
`after_commit :check_for_problems_later` enqueued unique `Scan::Model::CheckForProblemsJob`.
ActiveJob uniqueness acquired a Redlock against Redis; Redis timed out under mesh-preview
drain load (used memory ~172 Mi of a 256 Mi limit). The raise escaped into Puma as HTTP 500
after a successful save. Same *class* as RCA-002 (unique `perform_later` on an interactive
HTTP path); different surface (update, not merge).

ASMT-003 already flagged remaining **capacity/ops** under drain (not a design rewrite). Capacity
is co-hygiene: it dampens Redlock timeouts; it does not own interactive HTTP success.

Without a binding contract, later authors globally fail-open uniqueness, re-read `Current` in
`Model`, or treat a Redis PVC / YAML bump as the HTTP-500 fix. This ADR extends ADR 0002 to
the update surface so SPEC-002 / SPEC-003 implement it; they do not renegotiate the owner.

## Decision

**Model-update HTTP success is a function of the DB save only.** Interactive
`ModelsController#update` (turbo_stream / HTML) must **not** depend on uniqueness Redlock
succeeding. A uniqueness or Redis-client failure must not 500 the request or undo a committed
save.

1. **Soft-fail unique enqueue on the update HTTP path.** `Model#check_for_problems_later`
   (and any other unique `perform_later` that can fire from that after_commit) must not raise
   `Redlock::LockAcquisitionError` or Redis client timeouts into the request. Log at warn with
   **model id only** (no library/file paths, no secrets) and skip enqueue (or equivalent soft
   path). Follow-up full re-scan is existing scan / Phase B jobs, not the update response.
   HTTP 2xx does not require a uniqueness lock. SPEC-002 implements this.
2. **Global uniqueness stays `:raise`.** Do **not** set global
   `ActiveJob::Uniqueness` `on_redis_connection_error` off `:raise` (leave the initializer
   assignment commented / unset). Uniqueness remains valid for scan/worker jobs.
   `CheckForProblemsJob` stays `unique :until_executed`. Optional **per-job** non-raise on
   `CheckForProblemsJob` only is belt-and-suspenders, never the owner (same pattern as ADR 0002).
3. **Skip owner is still `ScanContext` / record flags.** Production skip is
   `skip_problem_check` / `suppress_problem_checks` on the record.
   **Do not** add a `Current.skip_problem_checks` (or other `Current.*`) read in `Model`
   (`suppress_problem_checks?` stays flags-only). `Current.set` may remain for observers; it is
   not the skip that protects update HTTP. ADR 0002 already forbade this; this ADR restates it
   for the update surface.
4. **Redis capacity is co-hygiene, not the class owner.** SPEC-003 may raise Redis memory
   (and CPU as needed) so drain traffic does not starve interactive enqueue. Keep emptyDir;
   **no Redis PVC**. Pin only the operator fork digest that contains SPEC-002 — never upstream.
   SPEC-003 MUST NOT claim the HTTP 500 class is closed by Redis YAML / a limit bump alone.

Spark / background scan jobs keep uniqueness. HTTP acceptance does not require them to succeed
on the update request.

### Ownership (fixed)

| Concern | Owner |
|---------|--------|
| App soft-fail: no Redlock raise into update HTTP; save stays committed | SPEC-002 (`Model#check_for_problems_later`, request specs) |
| Redis capacity: raise limits above live drain pressure; emptyDir; no PVC; fork pin after SPEC-002 digest | SPEC-003 (does **not** close the HTTP 500 class) |
| Invariant contract | this ADR |

## Consequences

- Update HTTP 2xx means the model row persisted — even if Redis uniqueness is down or timed out.
- A missed problem-check enqueue is recovered by later scan jobs, not by rolling back the save.
- Authors do not re-open `Current` reads in `Model`, globally fail-open uniqueness, add a Redis
  PVC, or treat a Redis limit bump as sufficient-alone for this 500 class.
- Deploy of the app-layer fix requires a new pinned fork image (SPEC-003 pin step). Redis YAML
  changes damp drain saturation; they are **not** sufficient-alone.

## Rejected approaches

| Do not | Why |
|--------|-----|
| Rescue the 500 only in `ModelsController` | after_commit still raises; user still sees failure (wrong layer) |
| Skip problem checks entirely on every update | Uniqueness and scans remain valid off the HTTP path (REQ-005) |
| Disable ActiveJob uniqueness globally, or set global `on_redis_connection_error` off `:raise` | Wrong owner; uniqueness stays required for scan jobs (REQ-003) |
| `Current.skip_problem_checks` read in `Model` to dodge the job | Flags-only skip already; Current skip is a no-op today (REQ-004, ADR 0002) |
| Redis PVC / Recreate / node pin / limit bump as the class close | Capacity is co-hygiene; PVC is a future queue-durability initiative (REQ-006, GR-002) |
| Pause or delete mesh-preview drip CronJob as the HTTP fix | Drain continues; LIMIT tweak only if prove still saturates Redis (GR-005) |
| Edit RCA-001 probe / health / liveness / `HEALTH_CHECK_SIDEKIQ` | Different failure class (GR-003) |
| Claim Redis GitOps closed the update 500 | App-layer ownership; SPEC-003 is hygiene + pin only (GR-002) |

## Forbidden

| Do not | Why |
|--------|-----|
| Let uniqueness Redlock raise into interactive model-update HTTP | Live 2026-08-28 class: Redis timeout 500s a committed save |
| Assign global `on_redis_connection_error` (fail-open or otherwise) | Default stays `:raise`; uniqueness remains valid for workers (REQ-003) |
| New `Current.skip_problem_checks` (or `Current.*`) read in `Model` | `suppress_problem_checks?` stays flags-only (REQ-004, ADR 0002) |
| Redis PVC as the HTTP-500 fix | Keep emptyDir; ephemeral queues rebuild from scans (REQ-006) |
| Claim Redis YAML / memory bump alone closed HTTP 500 | Capacity dampens; SPEC-002 owns the class (GR-002) |

## References

- Live incident: `ModelsController#update` → `after_commit check_for_problems_later` → unique
  `CheckForProblemsJob` → Redlock Redis timeout → HTTP 500 (2026-08-28)
- `ASMT-003` — `sdd/assessments/ASMT-003-manyfold-ai/` (capacity/ops residual under drain)
- `source: RCA-002` — `sdd/rca/RCA-002-manyfold-merge-resolve-redlock-500/` (same class, merge surface)
- Extends: `docs/adr/0002-merge-http-off-uniqueness-redlock.md` (`INIT-002`)
- Initiative: `INIT-005-manyfold-model-update-redis-capacity`
- Implements: SPEC-002 (soft-fail enqueue), SPEC-003 (Redis capacity + fork pin; no PVC)

---

Provenance: `INIT-005/SPEC-001`
