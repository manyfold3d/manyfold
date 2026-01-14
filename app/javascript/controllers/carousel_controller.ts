import { Controller } from '@hotwired/stimulus'

import { Carousel } from 'bootstrap'

// Connects to data-controller="carousel"
export default class extends Controller {
  paused = false
  manual = false
  carousel: Carousel | null = null

  connect (): void {
    this.carousel = new Carousel(this.element, { /* eslint no-new: 0 */
      interval: 5000,
      pause: this.paused
    })

    this.element.addEventListener('slid.bs.carousel', function (event) {
      document.querySelector(`.carousel-indicators > button:nth-child(${event.from + 1})`)?.removeAttribute('aria-disabled')
      document.querySelector(`.carousel-indicators > button:nth-child(${event.to + 1})`)?.setAttribute('aria-disabled', 'true')
    })
  }

  onPauseButton (): void {
    this.manual = true
    this.setPauseState(!this.paused)
  }

  onEnter (): void {
    if (this.manual) { return }
    this.setPauseState(true)
  }

  onLeave (): void {
    if (this.manual) { return }
    this.setPauseState(false)
  }

  setPauseState (pause: boolean): void {
    const icon = document.querySelector('#rotationControlIcon')
    this.paused = pause
    if (this.paused) {
      this.carousel?.pause()
      document.querySelector('#imageCarouselInner')?.setAttribute('aria-live', 'polite')
      icon?.classList.add('bi-play')
      icon?.classList.remove('bi-pause')
    } else {
      this.carousel?.cycle()
      document.querySelector('#imageCarouselInner')?.setAttribute('aria-live', 'off')
      icon?.classList.add('bi-pause')
      icon?.classList.remove('bi-play')
    }
  }
}
