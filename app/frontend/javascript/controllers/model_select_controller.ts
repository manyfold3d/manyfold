import { Controller } from '@hotwired/stimulus'

import TomSelect from 'tom-select'

// Connects to data-controller="model-select"
export default class extends Controller {
  tomSelect: TomSelect | null

  connect (): void {
    this.tomSelect = new TomSelect((this.element as HTMLSelectElement), {
      allowEmptyOption: false,
      valueField: 'id',
      labelField: 'name',
      searchField: ['name'],
      load: this.fetchData.bind(this)
    })
  }

  disconnect (): void {
    this.tomSelect?.destroy()
  }

  reconnect (): void {
    this.disconnect()
    this.connect()
  }

  fetchData (query, callback): void {
    const params = new URLSearchParams()
    params.append('q', query)
    fetch(`/models?${params.toString()}`, { headers: { Accept: 'application/vnd.manyfold.v0+json' } })
      .then(async response => await response.json())
      .then(json => {
        callback(
          json.member.map((it) => ({ id: it['@id'].split('/').pop(), name: it.name }))
        )
      }).catch(() => {
        callback()
      })
  }
}
