# ADR 0006: Manyfold as OctoPrint-like printer surface (GK3 Pro Phase 1)

**Status:** Accepted  
**Date:** 2026-08-28  
**Provenance:** `INIT-007/SPEC-001`

> This ADR is home_k3 SDD `INIT-007-manyfold-uniformation-print-monitor`.
> It does **not** adopt “Manyfold connects to an external OctoPrint” as the
> product for the operator’s UniFormation GK3 Pro. Upstream PrintHost’s
> OctoPrint/Moonraker *clients* remain useful for *other* hosts later; they are
> not the Phase 1 story for this printer.

---

## Context

Operators want Manyfold to feel like **opening OctoPrint**: see the live camera,
know the printer is registered, and (when a LAN protocol exists) start work from
files already in the library — **without** installing or pointing Manyfold at a
separate OctoPrint instance for this machine.

Live facts (operator probe, 2026-08-28):

| Fact | Detail |
| --- | --- |
| Device | UniFormation **GK3 Pro** @ `10.0.0.199` |
| Open | TCP **554 RTSP** (`ireader/media-server`); SDP H.264 `RTP/AVP 96` |
| Canonical URL | `rtsp://10.0.0.199:554/` (path-agnostic) |
| Closed | 80, 443, 3000, 3031, 8080, 8081, 8554, 5000 — no HTTP print UI |
| Control today | UniFormation App / CHITUBOX remote (proprietary) |

Research (`RSCH-001`) correctly recommended not greenfielding a full OctoPrint
clone for FDM hosts that already run OctoPrint. That advice does **not** mean
this initiative’s UX is “configure OctoPrint URL.” For GK3 Pro there **is** no
OctoPrint to connect to.

Browsers cannot play RTSP natively. In-app live view requires a **cluster
restreamer** (e.g. go2rtc) that pulls RTSP and offers WebRTC and/or HLS behind
Manyfold authz.

## Decision

**Phase 1 product: Manyfold *is* the OctoPrint-like surface for this printer —
live camera + printer registry + honest control UX — not an OctoPrint client.**

1. **Product framing — “like OctoPrint,” not “to OctoPrint.”** User-facing copy,
   settings, and ADRs describe a **printer monitor/control surface inside
   Manyfold**. Forbidden: primary CTA or settings that imply the operator must
   run OctoPrint (or Moonraker) for *this* GK3 Pro. Covered: REQ-001 reframed,
   operator clarification 2026-08-28.

2. **Printer registry (data shape).** Persist a first-class printer/host record
   (name, endpoint/source, credentials if any, camera/stream association). Prefer
   upstream `PrintHost` table/model **shape** from Manyfold ≥ v0.145 /
   `upstream-v0.146` so we do not invent a second registry — but Phase 1 AC for
   GK3 does **not** require enabling OctoPrint/Moonraker/PrusaLink/Odyssey
   “Print with…” against this device. Covered: REQ-002, REQ-003, GR-001.

3. **Live camera is P0.** Authenticated Manyfold UI shows the GK3 stream via a
   **cluster restreamer** (RTSP → WebRTC and/or HLS). Source of truth:
   `rtsp://10.0.0.199:554/`. Never claim native browser RTSP. Covered: REQ-004,
   GR-004. SPEC-004 + SPEC-005 own implementation.

4. **Print start/cancel Phase 1 honesty.** Until a documented or reverse-engineered
   UniFormation LAN print API is proven, start/cancel remains the **vendor app**,
   with clear in-app copy and optional docs link — **not** a fake OctoPrint upload
   success. In-app pause/temps/HMI is out of scope for Phase 1. Covered: REQ-007,
   REQ-008, REQ-010, REQ-011, GR-002, GR-005.

5. **Upstream protocol clients are deferred for this printer.** Porting
   `Print::OctoprintService` / Moonraker / etc. is allowed as scaffolding for
   *future other hosts*, but must be **gated** so unsupported protocols cannot
   report success against GK3. This initiative’s Phase 1 acceptance is camera +
   registry + authz + network prove — not “send GCODE to OctoPrint.” Covered:
   GR-002, GR-005.

6. **Secrets and exposure.** No RTSP passwords, printer tokens, or API keys in
   Git. Restreamer is cluster-internal; Manyfold authz is the front door. Vault /
   ESO / Rails encrypted credentials only. Covered: REQ-006, GR-003.

7. **Cluster reachability.** Restreamer (and Manyfold if needed) must reach
   `10.0.0.199:554` via NetworkPolicy / routing; fail loud if unreachable.
   Covered: REQ-005.

## Ownership

| Concern | Owner |
| --- | --- |
| Invariant (OctoPrint-*like* surface, not OctoPrint client) | This ADR (`INIT-007/SPEC-001`) |
| Printer registry schema | `INIT-007/SPEC-002` |
| Service/policy scaffold | `INIT-007/SPEC-003` |
| Settings + camera UI | `INIT-007/SPEC-004` |
| Restreamer + NetworkPolicy + pin | `INIT-007/SPEC-005` |
| Security review / diagrams | `INIT-007/SPEC-006`, `SPEC-007` |

## Consequences

- Operators get live camera in Manyfold without installing OctoPrint.
- Job push from library waits on UniFormation protocol research (parked).
- Authors must not ship “Print with OctoPrint” against GK3 without a live `ok?`.
- Future FDM users who *do* run OctoPrint can reuse PrintHost clients later under
  a separate prove — outside Phase 1 AC for this initiative.

## Rejected approaches

| Approach | Why rejected |
| --- | --- |
| Primary path = configure Manyfold → external OctoPrint for GK3 | No OctoPrint on device; wrong operator ask |
| Greenfield full OctoPrint HMI (temps, plugins, GCODE terminal) | Out of scope; vendor app owns control today |
| Native `<video src="rtsp://…">` in browser | Browsers do not speak RTSP |
| Public LoadBalancer for raw RTSP | Security; GR-003 |
| Claim Odyssey/Moonraker works on stock UniFormation | Unproven; GR-005 |
| Second parallel “camera device” table beside PrintHost | GR-001 — one registry |

## Forbidden

| Claim / pattern | Forbidden because |
| --- | --- |
| “Connect your OctoPrint” as the GK3 setup story | Operator ask is Manyfold *as* the surface |
| Silent success on print upload when protocol unsupported | Honesty / GR-002 |
| World-readable stream URL without session authz | REQ-006 |
| `??` inventing camera URL or inventing OctoPrint base URL | Fail loud |
| Secrets in GitOps plaintext | GR-003 |

## References

- `RSCH-001` + addendum (operator RTSP/SDP probe)
- Upstream PrintHost (Manyfold ≥ v0.145) — shape only for Phase 1
- Initiative: `INIT-007-manyfold-uniformation-print-monitor`
