import { Controller } from '@hotwired/stimulus'

import TomSelect from 'tom-select'

// Connects to data-controller="searchable-select"
export default class extends Controller {
  tomSelect: TomSelect | null

  connect (): void {
    this.tomSelect = new TomSelect((this.element as HTMLSelectElement), { // eslint-disable-line no-new
      allowEmptyOption: true
    })
  }

  disconnect (): void {
    this.tomSelect?.destroy()
  }

  reconnect (): void {
    this.disconnect()
    this.connect()
  }
}
