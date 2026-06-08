import { Controller } from '@hotwired/stimulus'

import TomSelect from 'tom-select'

// Connects to data-controller="collection-input"
export default class extends Controller {
  tomSelect: TomSelect | null

  connect (): void {
    this.tomSelect = new TomSelect((this.element as HTMLSelectElement), { // eslint-disable-line no-new
      plugins: ['remove_button']
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
