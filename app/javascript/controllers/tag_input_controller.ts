import { Controller } from '@hotwired/stimulus'

import TomSelect from 'tom-select'
import type { TomInput } from 'tom-select/dist/cjs/types'

// Connects to data-controller="tag-input"
export default class extends Controller {
  connect (): void {
    new TomSelect((this.element as TomInput), { // eslint-disable-line no-new
      addPrecedence: true,
      create: true,
      plugins: ['remove_button'],
      selectOnTab: true,
      onItemAdd: function () {
        this.setTextboxValue('')
        this.refreshOptions()
      }
    })
  }
}
