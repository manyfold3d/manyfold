# ADR 0003: Archive mesh grid uses in-image mesh_thumbnail PNGs

**Status:** Accepted  
**Date:** 2026-08-27  
**Provenance:** `INIT-003/SPEC-001`  
**source:** `ASMT-002`

> This ADR is home_k3 SDD `INIT-003-manyfold-archive-mesh-previews`. It is **not** manyfold-ai
> browse `INIT-003` (ADR 0001, infinite-scroll DRY). Do not reuse ADR 0001 provenance for
> archive mesh previews.

---

## Context

Archive (zip/rar/7z) model-file grids currently show **filenames**, not objects. ASMT-002
measured hundreds of thousands of mesh `archive_entries` still `listed` versus a small
`preview_ready` set. That is a **drain and honesty** problem, not a missing 3D engine.

The app image already contains Node and `scripts/mesh_thumbnail.mjs`: a software STL→PNG
thumbnail (CPU z-buffer, no GPU/WebGL in the worker). Non-STL members convert via Assimp
to a tempfile STL, then the same script. One archive member is extracted to
`.manyfold/archive_cache/` (or a tempfile); the PNG lands under
`.manyfold/derivatives/archives/`. `Components::ArchiveEntryCard` already `image_tag`s that
PNG when `preview_exists?`.

Library archive scan defaults to `preview_images_only: true`, so mesh members stay `listed`.
When Node render fails, `Archive::PreviewEntry#write_mesh_placeholder_preview!` draws
extension + basename onto a PNG and today still sets `status: preview_ready`. The card
then treats a filename card as a successful object preview.

Without a binding contract, later authors mount browser `ObjectPreview` / Three.js on every
zip row, unzip whole archives into the model folder, replace the in-image renderer, or
enqueue every listed mesh in one Sidekiq payload.

## Decision

**Archive grid thumbs are server PNGs produced in the app image. WebGL is only for
open/extract of a single file. A drawn filename is not success. Mesh preview work drips.
Archives are listed and extracted one member at a time — never exploded onto the library
folder.**

1. **Grid thumbs are in-image `scripts/mesh_thumbnail.mjs` PNGs.** Archive **grid**
   thumbnails for mesh members are PNGs written by that Node script running **in the
   application image**. Reuse the existing pipeline (`PreviewArchiveEntryJob` →
   `Archive::PreviewEntry#extract_mesh_and_preview!`). Do **not** add a second mesh
   renderer or a sidecar 3D service for the grid. Covered: REQ-001.
2. **No per-row `ObjectPreview` / Three.js on archive grids.** Browser WebGL
   (`renderer_controller` / `ObjectPreview`) is allowed only when the user **opens or
   extracts a single renderable file** (top-level model files, or an extracted archive
   member). Archive zip/rar/7z **grids** must not mount a canvas per row. Covered: REQ-002.
3. **Text/filename placeholder PNG is not `preview_ready`.** Drawing extension + basename
   (ImageMagick `draw text` or a minimal colored PNG) is a fallback visual, **not** a
   successful object preview. It must **not** set `status: preview_ready` (GR-005).
   `preview_ready` requires a real `mesh_thumbnail.mjs` PNG with size > 0. Node/script
   failure is `preview_failed` (or equivalent non-ready), not a lie. Covered: REQ-003,
   GR-005. SPEC-002 owns the code change.
4. **Paced drip only — never one-shot enqueue of all listed meshes.** Mesh preview jobs
   use batch / stagger / cursor (existing
   `Scan::EnqueueArchiveMeshPreviewRerendersJob`: `DEFAULT_BATCH = 100`,
   `DEFAULT_STAGGER = 0.5`, self-chain on `cursor`). Do **not** `perform_later` the full
   listed-mesh set in one payload (GR-002). GitOps CronJob (SPEC-004) must call this
   drip, not dump. Covered: REQ-004.
5. **Do not extract whole archives into model folders.** Listing reads the archive index
   without exploding members onto NFS. Preview/open extracts **one** pathname into
   `.manyfold/` cache or a tempfile, with existing size and path-safety gates
   (`EntryTooLarge`, `UnsafePath`). Members must not be unpacked as sibling files in the
   model directory. Covered: REQ-008, GR-001.

SPEC-002 / SPEC-003 / SPEC-004 implement this contract; they do not renegotiate the owner.

### Ownership (fixed)

| Concern | Owner |
|---------|--------|
| Assimp load before non-STL convert; placeholder ≠ `preview_ready`; STL-only script only after convert | SPEC-002 (`Archive::PreviewEntry`) |
| `ArchiveEntryCard`: real PNG vs loading/empty slot; no renderer on the card | SPEC-003 |
| GitOps CronJob drip of `EnqueueArchiveMeshPreviewRerendersJob` + fork image pin | SPEC-004 |
| Invariant contract (grid = in-image PNG; no grid WebGL; no full unzip; paced drip) | this ADR |

## Consequences

- Seeing an object in an archive grid means a software PNG from `mesh_thumbnail.mjs` exists
  on disk under library `.manyfold/derivatives/archives/` and `preview_exists?` is true.
- Filename-on-card and draw-text placeholders are **not** the done state (GR-005).
- Authors do not mount Three.js per zip row, unzip the library, replace
  `mesh_thumbnail.mjs`, or enqueue the entire listed-mesh backlog in one shot.
- SPEC-004 must not claim the class closed by a CronJob that dumps all jobs, or by pinning
  an image that still marks placeholders `preview_ready`.

## Rejected approaches

| Do not | Why |
|--------|-----|
| Per-row `ObjectPreview` / Three.js / `data-controller="renderer"` on archive cards | Hundreds of thousands of canvases; wrong cost model. WebGL is open/extract only (REQ-002) |
| New 3D engine or sidecar thumbnail service | Renderer is already in the image and used for ready meshes (ASMT-002). Finish the drain |
| Set `preview_images_only: false` and enqueue every listed mesh at once | Redis/NFS stampede (GR-002). Drip job exists for this reason (REQ-004) |
| Treat ImageMagick/draw-text (or empty colored) PNG as `preview_ready` | User still sees a filename; status would lie (REQ-003, GR-005) |
| Unzip the whole archive into the model / library folder | NFS invariant; listing must not explode members (REQ-008, GR-001) |
| Interactive WebGL in the worker (GPU/WebGL in Sidekiq) | Image renderer is software z-buffer Node; workers have no GPU contract |
| Replace `mesh_thumbnail.mjs` “because filenames look bad” | UI empty-state + drain policy; the script is not the defect |

## Forbidden

| Do not | Why |
|--------|-----|
| Mount `ObjectPreview` / Three.js on archive **grid** rows | REQ-002; grid thumbs are PNGs (REQ-001) |
| Mark text/filename placeholder PNG `preview_ready` | REQ-003, GR-005; SPEC-002 must distinguish placeholder vs real render |
| One-shot `perform_later` of all listed meshes (no batch/stagger/cursor) | REQ-004, GR-002 |
| Extract whole archives into model folders | REQ-008, GR-001 |
| Claim a new renderer or browser WebGL on the grid closed ASMT-002 | The renderer is correct; policy and `preview_ready` honesty are the work |

## References

- `source: ASMT-002` — `sdd/assessments/ASMT-002-manyfold-archive-mesh-preview/ASMT-002-manyfold-archive-mesh-preview-assessment-report.md`
- Initiative: `INIT-003-manyfold-archive-mesh-previews` (home_k3; **not** manyfold-ai browse INIT-003 / ADR 0001)
- In-image renderer: `scripts/mesh_thumbnail.mjs`
- Implements: SPEC-002 (Assimp + placeholder ≠ ready), SPEC-003 (`ArchiveEntryCard`),
  SPEC-004 (CronJob drip + fork pin)

---

Provenance: `INIT-003/SPEC-001`
