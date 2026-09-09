import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="problem-list-filter"
export default class extends Controller {
  static targets = ['query', 'row', 'empty']

  declare readonly queryTarget: HTMLInputElement
  declare readonly rowTargets: HTMLElement[]
  declare readonly hasEmptyTarget: boolean
  declare readonly emptyTarget: HTMLElement

  filter (): void {
    const needle = this.queryTarget.value.trim().toLowerCase()
    let visible = 0
    this.rowTargets.forEach((row) => {
      const haystack = row.dataset.search ?? row.textContent ?? ''
      const show = needle === '' || haystack.includes(needle)
      row.classList.toggle('hidden', !show)
      if (show) visible += 1
    })
    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle('hidden', visible > 0)
    }
  }
}
