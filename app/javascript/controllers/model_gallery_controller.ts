import { Controller } from '@hotwired/stimulus'

// Opens the shared browse lightbox, loads model images into a turbo-frame, and clears on close.
// Card buttons: data-action="click->model-gallery#open" with
// data-model-gallery-model-url-param, data-model-gallery-gallery-url-param,
// data-model-gallery-model-name-param.
export default class extends Controller {
  static targets = ['dialog', 'frame', 'title', 'openLink']

  declare dialogTarget: HTMLDialogElement
  declare hasDialogTarget: boolean
  declare frameTarget: HTMLElement
  declare hasFrameTarget: boolean
  declare titleTarget: HTMLElement
  declare hasTitleTarget: boolean
  declare openLinkTarget: HTMLAnchorElement
  declare hasOpenLinkTarget: boolean

  private lastFocused: HTMLElement | null = null
  private readonly boundBackdropClick = (e: MouseEvent): void => this.onBackdropClick(e)
  private readonly boundKeydown = (e: KeyboardEvent): void => this.trapKeydown(e)

  open (event: Event): void {
    event.preventDefault()
    event.stopPropagation()

    const params = (event as CustomEvent & { params: Record<string, string> }).params ?? {}
    const button = event.currentTarget as HTMLElement
    const modelUrl = params.modelUrl ?? button.dataset.modelGalleryModelUrlParam
    const galleryUrl = params.galleryUrl ?? button.dataset.modelGalleryGalleryUrlParam
    const modelName = params.modelName ?? button.dataset.modelGalleryModelNameParam ?? ''

    if (galleryUrl == null || modelUrl == null || !this.hasDialogTarget) return

    this.lastFocused = button

    if (this.hasTitleTarget) {
      this.titleTarget.textContent = modelName
    }
    if (this.hasOpenLinkTarget) {
      this.openLinkTarget.href = modelUrl
    }
    if (this.hasFrameTarget) {
      // Clear first so Turbo always fetches (same frame id reuse)
      this.frameTarget.removeAttribute('src')
      this.setLoadingFrame()
      this.frameTarget.setAttribute('src', galleryUrl)
    }

    this.dialogTarget.showModal()
    this.dialogTarget.addEventListener('click', this.boundBackdropClick)
    this.dialogTarget.addEventListener('keydown', this.boundKeydown)
    this.focusFirstFocusable()
  }

  close (event?: Event): void {
    if (event != null) event.preventDefault()
    if (!this.hasDialogTarget) return

    this.dialogTarget.removeEventListener('click', this.boundBackdropClick)
    this.dialogTarget.removeEventListener('keydown', this.boundKeydown)
    this.dialogTarget.close()
    this.clearFrame()

    if (this.lastFocused != null) {
      this.lastFocused.focus()
      this.lastFocused = null
    }
  }

  private loadingLabel (): string {
    return this.hasFrameTarget ? (this.frameTarget.dataset.loadingLabel ?? '') : ''
  }

  private setLoadingFrame (): void {
    if (!this.hasFrameTarget) return
    this.frameTarget.replaceChildren()
    const p = document.createElement('p')
    p.className = 'text-sm text-secondary-400 text-center py-12 m-0'
    p.textContent = this.loadingLabel()
    this.frameTarget.appendChild(p)
  }

  private clearFrame (): void {
    if (!this.hasFrameTarget) return
    this.frameTarget.removeAttribute('src')
    this.setLoadingFrame()
  }

  private focusFirstFocusable (): void {
    const focusable = this.getFocusables()
    if (focusable.length > 0) {
      focusable[0].focus()
    }
  }

  private getFocusables (): HTMLElement[] {
    const sel = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    return Array.from(this.dialogTarget.querySelectorAll<HTMLElement>(sel))
  }

  // INIT-006/SPEC-002: Escape closes; Tab focus trap. Arrow flip lives on carousel
  // (browse interval 0) so it connects after turbo-frame load without double-firing.
  private trapKeydown (event: KeyboardEvent): void {
    if (event.key === 'Escape') {
      this.close(event)
      return
    }
    if (event.key !== 'Tab') return
    const focusables = this.getFocusables()
    if (focusables.length === 0) return
    const first = focusables[0]
    const last = focusables[focusables.length - 1]
    if (event.shiftKey) {
      if (document.activeElement === first) {
        event.preventDefault()
        last.focus()
      }
    } else {
      if (document.activeElement === last) {
        event.preventDefault()
        first.focus()
      }
    }
  }

  private onBackdropClick (event: MouseEvent): void {
    if (event.target === this.dialogTarget) {
      this.close()
    }
  }
}
