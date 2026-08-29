import { Controller } from '@hotwired/stimulus'

// Toggle inline remaining-ml adjust form on resin bottle cards.
export default class extends Controller {
  static targets = ['form', 'toggle']

  declare readonly formTargets: HTMLElement[]

  toggle (event: Event): void {
    const button = event.currentTarget as HTMLElement
    const card = button.closest('article')
    if (card == null) return
    const form = card.querySelector<HTMLElement>('[data-resin-adjust-target="form"]')
    if (form == null) return
    form.classList.toggle('hidden')
  }
}
