# ADR 0007: Manyfold Resin Print Studio — Printer Manager Boundary

**Status:** Accepted  
**Date:** 2026-08-29  
**Provenance:** `INIT-008/SPEC-001`

> Product: Manyfold owns the **library**, a thin SDCP send/monitor path (`INIT-007` /
> ADR 0006), and now a full **printer manager** (Print Studio). The in-browser resin
> slicer (“Resin Forge”) is **out of scope** for INIT-008 and belongs in **INIT-009**.
> This ADR does not contradict ADR 0006: control plane for UniFormation / Elegoo-class
> resin printers remains **SDCP**, not OctoPrint.

---

## Context

Figma `Manyfold-Print-Studio` (`fileKey` `W0ZfwQA8QyGrtsxHfEaEhh`, canvas `02 Screens`
`3:3`) expanded to a cleaned **16-frame** flow that spans both shop-floor control and a
full slicer pipeline. Without a written cut, agents will implement Resin Forge inside
the manager initiative.

**Prior decision (ADR 0006):** Manyfold is the OctoPrint-*like* surface; GK3 / SDCP
hosts talk SDCP 3.0 directly. Phase 1 already sends already-sliced `CTB`/`JXS`.

**This decision:** define the **manager vs slicer** boundary, the **PrintJob** handoff
contract, the **plate-cleared** queue gate, and the canonical Figma node map for
INIT-008 implementation.

**SDD grounding (authoritative design map):**

- Relative to SDD tree:
  `home_k3/sdd/initiatives/INIT-008-manyfold-resin-print-studio/design/INIT-008-figma-grounding.md`
- Absolute on control node:
  `/home/bnelson/k8/home_k3/sdd/initiatives/INIT-008-manyfold-resin-print-studio/design/INIT-008-figma-grounding.md`
- Figma:
  https://www.figma.com/design/W0ZfwQA8QyGrtsxHfEaEhh/Manyfold-Print-Studio?node-id=3-3

Implement UI against those node IDs. Call `get_design_context` with
`skillNames: figma-design-to-code` before frontend coding; adapt to Phlex — never paste
React.

---

## Decision

### 1. Three-product glue

| Product | Owner INIT | Owns | Does not own |
| --- | --- | --- | --- |
| **Library** | Existing Manyfold | Models, meshes, federation, send-from-library entry | Machine control |
| **Printer manager (Print Studio)** | **INIT-008** | Printers, fleet, jobs, queue, compatibility gate, telemetry, consumables, history, model print log, on-printer storage | Supports, hollowing, exposure math, slice preview |
| **Slicer / Resin Forge** | **INIT-009** | Select parts → orient → hollow → supports → prepare plate → preflight → slice → emit `PrintJob` | Start/pause/cancel on the machine |

INIT-008 **extends** the INIT-007 registry (`print_hosts`, `Print::SdcpService`, go2rtc)
— one registry, SDCP-first (GR-006). Do not fork a second printer table.

### 2. Figma frame map — manager IN / slicer OUT

**Manager — IN SCOPE (INIT-008)**

| # | Frame | Node ID | Spec |
| --- | --- | --- | --- |
| 01 | Fleet Dashboard | `15:158` | SPEC-005 |
| 02 | Add Printer | `15:528` | SPEC-005 |
| 03 | Printer Monitor | `15:261` | SPEC-005 |
| 04 | Printer Settings | `24:925` | SPEC-007 |
| 05 | Send from Library | `15:586` | SPEC-005 |
| 13 | Job Queue | `23:1441` | SPEC-006 |
| 14 | Print History | `23:969` | SPEC-006 |
| 15 | Consumables & Maintenance | `23:1635` | SPEC-007 |
| 16 | Model Print Log | `23:1248` | SPEC-006 |

**Slicer / Resin Forge — OUT OF SCOPE → INIT-009**

| # | Frame | Node ID |
| --- | --- | --- |
| 06 | Select Parts | `16:933` |
| 07 | Orient & Position | `16:371` |
| 08 | Hollowing | `16:509` |
| 09 | Supports | `16:1095` |
| 10 | Prepare Plate | `15:352` |
| 11 | Pre-flight Check | `16:1219` |
| 12 | Slice Preview | `15:451` |

**Decorative / stub OK in INIT-008:** Bambu/X1C cards (unsupported — no send until a
later protocol INIT); Configure routing / Order supplies / Export CSV (REQ-015).

### 3. Manager does not slice (GR-001)

The printer manager **never** reimplements supports, hollowing, exposure math, or slice
preview. CTAs labeled “Open Prepare” / “Open in Slicer” are **disabled** or deep-link
**stubs** until INIT-009 exists. Send paths accept **already-sliced** artifacts (and
library files already in printable formats) only.

### 4. PrintJob contract (handoff from slicer → manager)

The slicer (INIT-009, or an external tool) **emits** a `PrintJob` (or equivalent durable
record the manager consumes). The manager **queues, gates, starts, monitors, and
histories** that job — it does not produce the slice.

**Minimum PrintJob field list** (schema detail lands in `INIT-008/SPEC-002`):

| Field / concern | Purpose |
| --- | --- |
| `print_host_id` | Target printer |
| `user_id` / actor | Who queued / confirmed |
| `state` | `queued` / `waiting_plate` / `printing` / `paused` / `succeeded` / `failed` / `cancelled` |
| `plate_cleared_at` | Manager-owned ack after successful plate clear (nullable until confirmed) |
| `sliced_artifact` / file ref | Link to CTB/JXS (or other gated format) + model association |
| `resin_profile` | Profile stamp used for compatibility gate |
| Target capabilities stamp | Format, resolution, Z height, AA when present — for gate |
| Estimates | Layers, duration, resin_ml (est) |
| Outcome / history | Terminal outcome, actual duration, actual resin_ml, failure_note |
| One active `printing` job per host | Enforced in service layer (REQ-006) |

Compatibility gate (REQ-004) hides Send and explains why when the artifact does not
match printer capabilities.

### 5. Plate-cleared is a manager-owned gate (REQ-009, GR-002)

After a successful print (or any path that requires a clear plate before the next start),
the **next queued job must not auto-start**.

- **Authority:** Manyfold manager state machine (`plate_cleared_at` / `waiting_plate`),
  not printer firmware and not an SDCP “auto-next” bit.
- **UX:** Job Queue board (`23:1441`) requires an explicit operator **plate-cleared**
  handshake before the next start is allowed.
- **Forbidden:** auto-start-next on job complete; silent promotion from `queued` →
  `printing` while the prior success lacks plate clear confirmation.

### 6. SDCP remains the driver — OctoPrint forbidden (extends ADR 0006, GR-004)

For UniFormation / Elegoo-class resin printers on the SDCP path:

- **Primary control plane:** SDCP WebSocket (+ UDP discover, HTTP upload) as in ADR 0006.
- **Forbidden:** using **OctoPrint** (or Moonraker / PrusaLink / Odyssey) as the SDCP
  driver or as the primary setup path for these machines.
- Bambu/X1C cards in Figma are decorative until a **separate** protocol INIT; hide send
  / mark unsupported — do not pretend they are SDCP hosts.

---

## Relationship to INIT-007 / ADR 0006

| Concern | ADR 0006 / INIT-007 | This ADR / INIT-008 |
| --- | --- | --- |
| Protocol | SDCP 3.0 for GK3 | Same — expand capabilities (storage, FEP/LCD, richer status) |
| Registry | `print_hosts` | Extend, do not fork |
| Camera | go2rtc restream | Reuse |
| Send | Already-sliced CTB/JXS | Same + queue, gate, history, consumables |
| Product surface | Thin monitor / send | Full Print Studio manager (nine Figma frames) |
| Slicer | Out of scope | Still out of scope → INIT-009 |

---

## Consequences

- Agents implement only manager frames `01–05`, `13–16`; slicer frames `06–12` are
  parked with node IDs preserved for INIT-009.
- Queue correctness depends on plate-cleared — resin shops never auto-start onto a dirty
  plate.
- PrintJob becomes the durable seam between library/slicer and machine control.
- OctoPrint-as-driver regressions remain forbidden for this printer class.

## Rejected approaches

| Approach | Why rejected |
| --- | --- |
| Ship Resin Forge inside INIT-008 | Wrong bounded context; scope creep (GR-001) |
| Auto-start next job on SDCP complete | Unsafe for resin; violates plate-cleared (GR-002) |
| OctoPrint client as UniFormation/Elegoo driver | Wrong stack; contradicts ADR 0006 |
| Second printer registry for “studio” | Violates GR-006 |
| Treat Bambu cards as SDCP-sendable | Unproven; decorative until later INIT |

## Forbidden

| Claim / pattern | Forbidden because |
| --- | --- |
| Implementing frames `06–12` under INIT-008 | Manager/slicer boundary |
| Auto-start-next without plate-cleared | GR-002 / REQ-009 |
| Slicer engine / exposure / supports in manager | GR-001 |
| “Connect OctoPrint” as SDCP path for resin UniFormation/Elegoo-class | ADR 0006 + this ADR |
| Silent gate bypass when format/resolution/Z fail | REQ-004 honesty |

## References

- ADR 0006 — Manyfold as OctoPrint-like printer surface via SDCP (GK3 Pro)
- Initiative: `INIT-008-manyfold-resin-print-studio`
- Design map: `design/INIT-008-figma-grounding.md` (see paths under Context)
- Follow-on: `INIT-009` (Resin Forge / slicer) — recommended, not started here
- SDCP 3.0 — cbd-tech/SDCP-Smart-Device-Control-Protocol-V3.0.0
