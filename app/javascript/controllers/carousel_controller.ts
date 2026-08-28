import { Controller } from '@hotwired/stimulus'

// Standalone carousel (no Bootstrap JS). Toggles .active on slides, syncs indicators, auto-advances.
// Requires: data-carousel-target="inner" on the slides container, "slide" on each .carousel-item, "indicator" on each indicator button.
export default class extends Controller {
  static targets = ['inner', 'slide', 'indicator']
  static values = {
    index: { type: Number, default: 0 },
    interval: { type: Number, default: 5000 },
    paused: { type: Boolean, default: false }
  }

  declare innerTarget: HTMLElement
  declare hasInnerTarget: boolean
  declare slideTargets: HTMLElement[]
  declare hasSlideTarget: boolean
  declare indicatorTargets: HTMLElement[]
  declare hasIndicatorTarget: boolean
  declare indexValue: number
  declare intervalValue: number
  declare pausedValue: boolean

  private timer: ReturnType<typeof setInterval> | null = null
  private manual = false
  // INIT-006/SPEC-002: browse mode (interval 0) listens for arrows after turbo-frame connect.
  private readonly boundBrowseKeydown = (e: KeyboardEvent): void => this.onBrowseKeydown(e)

  connect (): void {
    this.syncSlide()
    this.startTimer()
    if (this.intervalValue <= 0) {
      this.element.ownerDocument.addEventListener('keydown', this.boundBrowseKeydown)
    }
  }

  disconnect (): void {
    this.stopTimer()
    if (this.intervalValue <= 0) {
      this.element.ownerDocument.removeEventListener('keydown', this.boundBrowseKeydown)
    }
  }

  private onBrowseKeydown (event: KeyboardEvent): void {
    const dialog = this.element.closest('dialog')
    if (dialog != null && !dialog.open) return
    if (event.key === 'ArrowLeft') {
      event.preventDefault()
      this.prev()
    } else if (event.key === 'ArrowRight') {
      event.preventDefault()
      this.next()
    }
  }

  next (): void {
    const n = this.hasSlideTarget ? this.slideTargets.length : 0
    if (n === 0) return
    this.indexValue = (this.indexValue + 1) % n
    this.syncSlide()
    this.resetTimer()
  }

  prev (): void {
    const n = this.hasSlideTarget ? this.slideTargets.length : 0
    if (n === 0) return
    this.indexValue = (this.indexValue - 1 + n) % n
    this.syncSlide()
    this.resetTimer()
  }

  goTo (event: Event): void {
    const el = event.currentTarget as HTMLElement
    const raw = el.getAttribute('data-carousel-index-param')
    if (raw !== null) {
      const i = parseInt(raw, 10)
      if (!Number.isNaN(i)) {
        this.indexValue = i
        this.syncSlide()
        this.resetTimer()
      }
    }
  }

  onPauseButton (): void {
    this.manual = true
    this.pausedValue = !this.pausedValue
    this.updatePauseState()
  }

  onEnter (): void {
    if (!this.manual) this.pausedValue = true
    this.updatePauseState()
  }

  onLeave (): void {
    if (!this.manual) this.pausedValue = false
    this.updatePauseState()
  }

  private syncSlide (): void {
    const idx = this.indexValue
    if (this.hasSlideTarget) {
      this.slideTargets.forEach((slide, i) => {
        slide.classList.toggle('active', i === idx)
      })
    }
    if (this.hasIndicatorTarget) {
      this.indicatorTargets.forEach((btn, i) => {
        const active = i === idx
        btn.classList.toggle('active', active)
        btn.setAttribute('aria-current', active ? 'true' : 'false')
        btn.setAttribute('aria-disabled', active ? 'true' : 'false')
      })
    }
    if (this.hasInnerTarget) {
      this.innerTarget.setAttribute('aria-live', this.pausedValue ? 'polite' : 'off')
    }
  }

  private updatePauseState (): void {
    if (this.pausedValue) {
      this.stopTimer()
      if (this.hasInnerTarget) this.innerTarget.setAttribute('aria-live', 'polite')
      this.updatePauseIcon(true)
    } else {
      this.startTimer()
      if (this.hasInnerTarget) this.innerTarget.setAttribute('aria-live', 'off')
      this.updatePauseIcon(false)
    }
  }

  private updatePauseIcon (paused: boolean): void {
    const icon = document.querySelector('#rotationControlIcon')
    if (icon !== null) {
      icon.classList.toggle('bi-play', paused)
      icon.classList.toggle('bi-pause', !paused)
    }
  }

  private startTimer (): void {
    this.stopTimer()
    if (this.pausedValue) return
    const ms = this.intervalValue
    if (ms <= 0) return
    this.timer = setInterval(() => this.next(), ms)
  }

  private stopTimer (): void {
    if (this.timer !== null) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  private resetTimer (): void {
    if (!this.pausedValue) this.startTimer()
  }
}
