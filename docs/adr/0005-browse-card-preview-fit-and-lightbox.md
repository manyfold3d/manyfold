# ADR 0005: Browse card preview fit and in-browse lightbox ownership

**Status:** Accepted  
**Date:** 2026-08-28  
**Provenance:** `INIT-006/SPEC-001`

> This ADR is home_k3 SDD `INIT-006-manyfold-browse-card-preview-fit`. It does not
> renegotiate ADR 0001 (browse infinite-scroll DRY) or ADR 0003 (archive grid mesh
> PNGs). There is no prior card-slot ADR; the reserved 4:3 slot is the
> `ModelCardPreview` outer box plus lite `PreviewFrame` absolute fill.

---

## Context

Operators need the **whole** preview visible on model browse cards, and they need
to flip through a model’s images **without leaving the models index**.

As-built (cite, do not treat as the decision):

- Lite `PreviewFrame` fills the reserved slot with `object-cover`, which crops
  (`app/components/preview_frame.rb` `#image_class`). Lite never mounts WebGL.
- The reserved height is the `ModelCardPreview` `aspect-[4/3]` outer box with
  absolute fill of the inner control (`app/components/model_card_preview.rb`).
- An in-browse lightbox already exists: Stimulus `model-gallery` on
  `app/views/models/_list.html.erb`, member `GET /models/:id/gallery`
  (`ModelsController#gallery`), turbo-frame body
  `ImageCarousel(images:, browse: true)` in `app/views/models/gallery.html.erb`.
- The preview control opens that lightbox only when `gallery: true` **and**
  `gallery_eligible?` (preview file present and `is_image?`). Otherwise the
  preview is a link to the model. Title / Open remain model navigation.

Without a binding contract, later authors add a second dialog/carousel, make the
whole card click open the gallery, crop cards forever, or mount Three.js in the
browse lightbox.

## Decision

**Lite browse-card previews fit (`object-contain`) inside the existing 4:3 slot.
The sole in-browse flip surface is `model-gallery` + `GET …/gallery` +
`ImageCarousel(browse: true)`. Mesh WebGL stays off that path.**

1. **Lite card images use `object-contain`, not `object-cover`.** Model browse
   lite `PreviewFrame` (local image and remote federated `type: Image`) shows the
   full image in the reserved 4:3 slot. Letterbox/pillarbox on
   `bg-secondary-100` / `dark:bg-secondary-800` is acceptable. Absolute
   `inset-0 w-full h-full` fill of the slot stays. Covered: REQ-001, REQ-002,
   GR-003. SPEC-002 owns the class change.
2. **Do not remove or collapse the reserved 4:3 slot.** Card height must not
   reflow when the image loads. Owner is `ModelCardPreview`’s
   `relative w-full aspect-[4/3]` plus lite `PreviewFrame`
   `absolute inset-0 overflow-hidden`. Covered: REQ-002, GR-003.
3. **Sole in-browse flip surface.** Flip-through on the models index uses only:
   - Stimulus controller `model-gallery`
     (`app/javascript/controllers/model_gallery_controller.ts`)
   - Member `GET /models/:id/gallery` (`ModelsController#gallery`, layout false,
     turbo-frame `model-gallery`)
   - `ImageCarousel(images: @images, browse: true)`
     (`app/views/models/gallery.html.erb`)
   Do not invent a second lightbox, dialog, or carousel library. Browse mode
   keeps interval `0` (no autoplay) and omits show-page edit overlays. Covered:
   REQ-003, REQ-004, GR-001.
4. **Eligibility is image preview, not the whole card.** The gallery **button**
   wraps the preview only when `gallery: true` and `gallery_eligible?`
   (`preview_file` present and `is_image?`). Mesh / empty / non-image previews
   keep the existing model link. Title, Open, and other card chrome still
   navigate to `/models/:id`. Preview click must not navigate. Covered: REQ-003,
   GR-002.
5. **Lightbox behavior.** Models with two or more policy-scoped images expose
   prev/next and indicators. Escape closes the dialog and returns focus to the
   preview control. ArrowLeft / ArrowRight flip while focus is in the open
   dialog. “Open model” (`data-model-gallery-target="openLink"`,
   `data-turbo-frame="_top"`) navigates to the model show page. Covered:
   REQ-004, REQ-005, REQ-006. SPEC-002 hardens keyboard + turbo-frame Stimulus
   connect.
6. **Authz unchanged.** `ModelsController#gallery` loads images via
   `policy_scope(@model.model_files)`. `ModelPolicy#gallery?` stays equivalent
   to `show?`. No new unauthenticated disclosure; no secrets or library paths in
   client logs. Covered: REQ-007, GR-004.
7. **No mesh / Three.js in the browse lightbox.** The browse dialog loads
   images only. Do not mount `ObjectPreview`, `renderer` Stimulus, or WebGL in
   that dialog this initiative. Lite cards already skip WebGL
   (`PreviewFrame` `lite: true`). Archive grid WebGL remains ADR 0003. Covered:
   GR-005.

SPEC-002 implements contain + flip harden. SPEC-003 pins the fork image. They
do not renegotiate this owner.

### Ownership (fixed)

| Concern | Owner |
|---------|--------|
| Lite / remote Image CSS `object-contain`; keep 4:3 absolute slot | SPEC-002 (`PreviewFrame`) |
| Gallery turbo-frame carousel connect; ArrowLeft/ArrowRight; tests | SPEC-002 (`model-gallery`, `carousel`, `ImageCarousel`) |
| Fork digest pin after merge | SPEC-003 |
| Invariant (fit, sole lightbox, eligibility, forbidden stacks) | this ADR |

## Consequences

- Seeing the full object on a browse card means lite `PreviewFrame` used
  `object-contain` inside the reserved slot, not a new card size.
- Flip-through on `/models` means `model-gallery` opened `GET …/gallery` into
  the existing dialog; the URL stays on browse until “Open model”.
- Authors do not add a parallel lightbox, bind gallery to the whole card, drop
  the 4:3 slot, or put a mesh canvas in the browse dialog.
- ADR 0001 still applies: gallery chrome stays **outside** the shared
  infinite-scroll partial (`application/browse_infinite_grid`).

## Rejected approaches

| Do not | Why |
|--------|-----|
| Second lightbox / carousel stack (new dialog, PhotoSwipe, Swiper, …) | GR-001; stack already exists (`model-gallery` + `ImageCarousel` browse) |
| Whole-card click = gallery | GR-002; title / Open must still go to the model |
| Replace BrowseGrid or the infinite-scroll shell to “make room” for a gallery | ADR 0001; gallery is surface chrome outside the shared partial |
| `object-cover` on lite card images “to fill the tile” | REQ-001; crop is the defect |
| Remove `aspect-[4/3]` / absolute fill so contain can “size naturally” | REQ-002, GR-003; reflow regression |
| Mount Three.js / `ObjectPreview` / `renderer` in the browse lightbox | GR-005; images only |
| Skip `policy_scope` on gallery files | REQ-007, GR-004 |

## Forbidden

| Do not | Why |
|--------|-----|
| Invent a second in-browse lightbox or carousel stack | GR-001; sole surface is `model-gallery` + `GET …/gallery` + `ImageCarousel(browse: true)` |
| Make the whole card click open the gallery | GR-002; preview control only when eligible |
| Mount mesh WebGL (`ObjectPreview` / `renderer` / Three.js) in the browse lightbox | GR-005 |

## References

- Initiative: `INIT-006-manyfold-browse-card-preview-fit` (home_k3 SDD)
- Implements: SPEC-002 (contain + lightbox harden), SPEC-003 (fork pin)
- ADR 0001 — gallery chrome outside shared infinite-scroll partial
- ADR 0003 — archive **grid** thumbs are PNGs; this ADR forbids WebGL in the
  **browse lightbox** (different surface, same “no canvas on browse” intent)
- As-built: `app/components/preview_frame.rb`,
  `app/components/model_card_preview.rb`,
  `app/javascript/controllers/model_gallery_controller.ts`,
  `app/views/models/_list.html.erb`,
  `app/controllers/models_controller.rb` `#gallery`,
  `app/views/models/gallery.html.erb`,
  `app/components/image_carousel.rb` (`browse: true`)

---

Provenance: `INIT-006/SPEC-001`
