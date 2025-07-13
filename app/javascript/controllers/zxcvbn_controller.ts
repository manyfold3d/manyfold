import { Controller } from '@hotwired/stimulus'

import { zxcvbn, zxcvbnOptions } from '@zxcvbn-ts/core'
import * as zxcvbnCommonPackage from '@zxcvbn-ts/language-common'
import * as zxcvbnEnPackage from '@zxcvbn-ts/language-en'

// Connects to data-controller="zxcvbn"
export default class extends Controller {
  meter: HTMLDivElement | null = null
  minScore = 4

  connect (): void {
    zxcvbnOptions.setOptions({
      translations: zxcvbnEnPackage.translations,
      graphs: zxcvbnCommonPackage.adjacencyGraphs,
      dictionary: {
        ...zxcvbnCommonPackage.dictionary,
        ...zxcvbnEnPackage.dictionary
      }
    })
    this.meter = this.element.parentElement?.querySelector('.zxcvbn-meter') ?? null
    this.minScore = parseInt(this.meter?.dataset.zxcvbnMinScore ?? '4')
  }

  value (): string {
    return (this.element as HTMLInputElement).value
  }

  onInput (event: InputEvent): void {
    const widths = ['w-0', 'w-25', 'w-50', 'w-75', 'w-100']
    const severities = ['bg-danger', 'bg-danger', 'bg-danger', 'bg-warning', 'bg-success', 'bg-success', 'bg-success', 'bg-success', 'bg-success'].slice(4 - this.minScore, 4 - this.minScore + 5)
    const result = zxcvbn(this.value())
    if (this.meter != null) {
      this.meter.className = `progress-bar zxcvbn-meter ${widths[result.score]} ${severities[result.score]}`
      this.meter.textContent = String(result.feedback.warning ?? '')
    }
  }
}

document.querySelectorAll('[data-zxcvbn]').forEach((element: HTMLInputElement) => {
})
