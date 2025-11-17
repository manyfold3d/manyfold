import { Controller } from '@hotwired/stimulus'

import TomSelect from 'tom-select'
import type { TomInput } from 'tom-select/dist/cjs/types'

// Connects to data-controller="tag-input"
export default class extends Controller {
  tomSelect: TomSelect | null

  connect (): void {
    this.tomSelect = new TomSelect((this.element as TomInput), { // eslint-disable-line no-new
      addPrecedence: true,
      create: true,
      plugins: ['remove_button'],
      onItemAdd: function () {
        this.setTextboxValue('')
        this.refreshOptions()
      }
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
