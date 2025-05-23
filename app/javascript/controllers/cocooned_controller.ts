import { Controller } from '@hotwired/stimulus'

import Cocooned from '@notus.sh/cocooned'

// Connects to data-controller="i18n"
export default class extends Controller {
  connect (): void {
    Cocooned.create(this.element)
  }
}
