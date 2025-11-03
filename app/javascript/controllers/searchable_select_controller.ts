import { Controller } from '@hotwired/stimulus'

import TomSelect from 'tom-select'
import type { TomInput } from 'tom-select/dist/cjs/types'

// Connects to data-controller="searchable-select"
export default class extends Controller {
  tomSelect: TomSelect | null

  connect (): void {
    this.tomSelect = new TomSelect((this.element as TomInput), { // eslint-disable-line no-new
      selectOnTab: true,
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
