import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="obfuscated-text"
export default class extends Controller {
  toggle (): void {
    const hidden = this.element.querySelectorAll('.obfuscated')
    const shown = this.element.querySelectorAll('.deobfuscated')
    hidden.forEach((element: HTMLElement) => {
      element.classList.replace('obfuscated', 'deobfuscated')
    })
    shown.forEach((element: HTMLElement) => {
      element.classList.replace('deobfuscated', 'obfuscated')
    })
  }
}
