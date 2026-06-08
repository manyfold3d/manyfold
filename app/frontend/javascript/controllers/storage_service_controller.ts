import { Controller } from '@hotwired/stimulus'

import { Collapse } from 'bootstrap'

// Connects to data-controller="storage-service"
export default class extends Controller {
  connect (): void {
    this.onChange()
  }

  onChange (): void {
    this.updateSections((this.element as HTMLSelectElement).value)
  }

  updateSections (active: string): void {
    const selected = 'options-' + active
    document.querySelectorAll('.storage-collapse').forEach((section: HTMLDivElement) => {
      const control = Collapse.getOrCreateInstance(section, { toggle: false })
      if (section.id === selected) {
        control.show()
      } else {
        control.hide()
      }
    })
  }
}
