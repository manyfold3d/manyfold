import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="editable"
export default class extends Controller {
  static values = {
    text: String
  }

  declare textValue: string

  copy (): void {
    void navigator.clipboard.writeText(this.textValue)
  }
}
