import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="caber-advanced"
export default class extends Controller {
  connect (): void {
    this.update()
  }

  update (): void {
    const advancedPanel: HTMLDivElement | undefined | null = this.element.closest('form')?.querySelector('#advanced-permissions')
    if (advancedPanel == null) { return }
    if ((this.element as HTMLInputElement).value === '') {
      advancedPanel.style.display = 'block'
    } else {
      advancedPanel.style.display = 'none'
    }
  }
}
