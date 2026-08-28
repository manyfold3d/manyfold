# ADR 0006: Manyfold as OctoPrint-like printer surface via SDCP (GK3 Pro)

**Status:** Accepted (amended 2026-08-28)  
**Date:** 2026-08-28  
**Provenance:** `INIT-007/SPEC-001`  
**Amendment source:** `RSCH-002`

> Product: Manyfold **is** the OctoPrint-*like* surface. Control plane for UniFormation
> GK3 Pro is **SDCP 3.0**, not an external OctoPrint. Upstream OctoPrint/Moonraker
> clients may exist later for *other* hosts; they are not Phase 1 for this printer.

---

## Context

Operators want Manyfold to feel like opening OctoPrint: live camera, status,
pause/stop, and send a sliced file — without installing OctoPrint.

**Live prove (`RSCH-002`, 2026-08-28) on `10.0.0.199`:**

| Fact | Detail |
| --- | --- |
| Protocol | CBD-Tech **SDCP V3.0.0** (ChituManager family) |
| Discover | UDP `:3000` payload `M99999` → UniFormation / GK3 GK3Pro / `MainboardID=d307202d8c1e0100` |
| Control | `ws://10.0.0.199:3030/websocket` — Cmd 0 status, Cmd 1 attributes |
| Caps | `FILE_TRANSFER`, `PRINT_CONTROL`, `VIDEO_STREAM` |
| Files | `CTB`, `JXS` |
| Video | Cmd 386 → `rtsp://10.0.0.199:554/video` |
| Upload HTTP | `http://10.0.0.199:3030/uploadFile/upload` |

Browsers cannot play RTSP. Live view uses a **cluster restreamer** (go2rtc) behind
Manyfold authz.

Early TCP-only scans that reported “no print API” are **superseded** by SDCP prove.

## Decision

**Phase 1: Manyfold talks SDCP to the GK3 Pro and restreams its camera — it does
not connect to OctoPrint.**

1. **Product framing — “like OctoPrint,” not “to OctoPrint.”** No primary CTA that
   requires an OctoPrint install for this machine.

2. **Control plane = SDCP.** Implement `Print::SdcpService` (discover, `ok?`,
   attributes, status, video enable/URL, HTTP upload, start/pause/stop/continue).
   Spec: [SDCP 3.0](https://github.com/cbd-tech/SDCP-Smart-Device-Control-Protocol-V3.0.0).

3. **Printer registry.** Upstream `PrintHost` **shape**; `protocol: "sdcp"`;
   persist endpoint base (`http://IP:3030`) and `mainboard_id`. Do not invent a
   second registry.

4. **Live camera.** Restream `rtsp://10.0.0.199:554/video` (or URL from Cmd 386)
   via go2rtc → WebRTC/HLS; never native browser RTSP.

5. **Send-from-library.** Phase 1 sends **already-sliced** `CTB`/`JXS` only.
   Upload via SDCP HTTP then Cmd `128`. Fail loud on format/encryption rejection —
   no silent success. Auto-slice STL/3MF is out of scope.

6. **Reject for this printer:** OctoPrint, Moonraker, PrusaLink, and Odyssey as
   the GK3 path (wrong stack / unproven on stock UniFormation).

7. **Secrets / exposure.** Cluster-internal go2rtc; Manyfold session auth front
   door; NetworkPolicy egress to printer CIDR for **3000/udp, 3030/tcp, 554/tcp**;
   no secrets in Git.

8. **Cluster reachability.** Fail loud if SDCP or RTSP unreachable from pods.

## Ownership

| Concern | Owner |
| --- | --- |
| Invariant (SDCP surface, not OctoPrint client) | This ADR |
| Registry schema | `INIT-007/SPEC-002` |
| `Print::SdcpService` + job + policy | `INIT-007/SPEC-003` |
| UI (camera, status, control, send) | `INIT-007/SPEC-004` |
| go2rtc + NetworkPolicy + pin | `INIT-007/SPEC-005` |
| Security / diagrams | `INIT-007/SPEC-006`, `SPEC-007` — see `home_k3/sdd/initiatives/INIT-007-…/design/architecture.md` |

## Consequences

- Operators get camera + status + control + (when format works) send-to-print in
  Manyfold without OctoPrint.
- ChituManager / UniFormation App remain valid alternate clients on the same SDCP.
- Authors must not ship “Print with OctoPrint” against GK3.

## Rejected approaches

| Approach | Why rejected |
| --- | --- |
| Connect Manyfold → external OctoPrint for GK3 | No OctoPrint; wrong ask |
| Vendor-app-only Phase 1 (camera only) | Superseded — SDCP proven (`RSCH-002`) |
| Odyssey `:12357` client | Wrong engine for stock UniFormation |
| Native browser RTSP | Unsupported |
| Public LB for RTSP/SDCP | Security |
| Second camera-only table | One PrintHost registry |

## Forbidden

| Claim / pattern | Forbidden because |
| --- | --- |
| “Connect your OctoPrint” as GK3 setup | Operator ask + wrong stack |
| Silent upload/start success when SDCP Nacks | Honesty |
| World-readable stream or unauthenticated print cmds | Authz |
| Advertising send for GCODE/STL without slice | GR-006 |
| Secrets in GitOps plaintext | GR-003 |

## References

- `RSCH-002` — how-to + live SDCP prove  
- `RSCH-001` — PrintHost shape (partially superseded on live API)  
- SDCP 3.0 MIT spec — cbd-tech/SDCP-Smart-Device-Control-Protocol-V3.0.0  
- Initiative: `INIT-007-manyfold-uniformation-print-monitor`
