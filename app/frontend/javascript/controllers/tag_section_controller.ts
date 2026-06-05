import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="tag-section"
export default class extends Controller {
  connect (): void {
    const status = window.localStorage.getItem(this.storageKey())
    if (status === 'open') {
      this.element.setAttribute('open', 'open')
    }
  }

  storageKey (): string {
    return `details-${this.element.id}`
  }

  saveState (): void {
    const state = (this.element.getAttribute('open') == null) ? '' : 'open'
    window.localStorage.setItem(this.storageKey(), state)
  }
}
