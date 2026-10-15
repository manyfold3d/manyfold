import { Controller } from '@hotwired/stimulus'

import { Carousel } from 'bootstrap'

// Connects to data-controller="carousel"
export default class extends Controller {
  // Paused by the user (pause button or manual navigation); what the button shows
  paused = false
  // The user has used the button or navigated; from then on hover is ignored
  manual = false
  hovering = false
  autoSlide = false
  carousel: Carousel | null = null

  connect (): void {
    // No data-bs-ride on the element: with it, Bootstrap restarts cycling after
    // every arrow or indicator click, overriding pause and hover. Cycling is
    // started here instead, so only this controller decides when it runs.
    const carousel = new Carousel(this.element, { /* eslint no-new: 0 */
      interval: 5000,
      pause: false
    })
    this.carousel = carousel

    // Mark slides made by the rotation timer, so any other slide (arrows,
    // indicators, keyboard, swipe) can be told apart as the user's own.
    const next = carousel.nextWhenVisible.bind(carousel)
    carousel.nextWhenVisible = () => {
      this.autoSlide = true
      try { next() } finally { this.autoSlide = false }
    }

    // A slide the user makes stops rotation until they press play. Bootstrap
    // fires this before deciding whether to resume cycling, so the pause holds.
    this.element.addEventListener('slide.bs.carousel', () => {
      if (this.autoSlide) { return }
      this.manual = true
      this.setPauseState(true)
    })

    this.element.addEventListener('slid.bs.carousel', function (event) {
      document.querySelector(`.carousel-indicators > button:nth-child(${event.from + 1})`)?.removeAttribute('aria-disabled')
      document.querySelector(`.carousel-indicators > button:nth-child(${event.to + 1})`)?.setAttribute('aria-disabled', 'true')
    })

    this.updateRotation()
  }

  disconnect (): void {
    // Turbo swaps pages without a reload, so stop the rotation timer here.
    // dispose() alone doesn't clear it, and the timer would then call a method
    // dispose() has nulled out, throwing every interval.
    this.carousel?.pause()
    this.carousel?.dispose()
    this.carousel = null
  }

  onPauseButton (): void {
    this.manual = true
    this.setPauseState(!this.paused)
  }

  // Hover pauses rotation without changing the button, so the pause button
  // (which sits inside the carousel) works on the first click.
  onEnter (): void {
    this.hovering = true
    this.updateRotation()
  }

  onLeave (): void {
    this.hovering = false
    this.updateRotation()
  }

  setPauseState (pause: boolean): void {
    const icon = document.querySelector('#rotationControlIcon')
    this.paused = pause
    icon?.classList.toggle('bi-play', pause)
    icon?.classList.toggle('bi-pause', !pause)
    this.updateRotation()
  }

  updateRotation (): void {
    const rotating = !this.paused && !(this.hovering && !this.manual)
    if (rotating) {
      this.carousel?.cycle()
    } else {
      this.carousel?.pause()
    }
    document.querySelector('#imageCarouselInner')?.setAttribute('aria-live', rotating ? 'off' : 'polite')
  }
}
