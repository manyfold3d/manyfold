import { zxcvbn, zxcvbnOptions } from '@zxcvbn-ts/core'
import * as zxcvbnCommonPackage from '@zxcvbn-ts/language-common'
import * as zxcvbnEnPackage from '@zxcvbn-ts/language-en'

document.addEventListener('ManyfoldReady', () => {
  zxcvbnOptions.setOptions({
    translations: zxcvbnEnPackage.translations,
    graphs: zxcvbnCommonPackage.adjacencyGraphs,
    dictionary: {
      ...zxcvbnCommonPackage.dictionary,
      ...zxcvbnEnPackage.dictionary
    }
  })

  document.querySelectorAll('[data-zxcvbn]').forEach((element: HTMLInputElement) => {
    const meter = element.parentElement?.querySelector('.zxcvbn-meter') as HTMLDivElement
    const widths = ['w-0', 'w-25', 'w-50', 'w-75', 'w-100']
    const minScore = parseInt(meter.dataset.zxcvbnMinScore ?? '4')
    const severities = ['bg-danger', 'bg-danger', 'bg-danger', 'bg-warning', 'bg-success', 'bg-success', 'bg-success', 'bg-success', 'bg-success'].slice(4 - minScore, 4 - minScore + 5)
    element.addEventListener('input', (event: InputEvent) => {
      if ((event.target as HTMLInputElement)?.value != null) {
        const result = zxcvbn((event.target as HTMLInputElement)?.value)
        meter.className = `progress-bar zxcvbn-meter ${widths[result.score]} ${severities[result.score]}`
      }
    })
  })
})
