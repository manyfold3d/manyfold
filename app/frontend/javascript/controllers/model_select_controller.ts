import { Controller } from '@hotwired/stimulus'

import TomSelect from 'tom-select'

// Connects to data-controller="model-select"
export default class extends Controller {
  tomSelect: TomSelect | null

  connect (): void {
    this.tomSelect = new TomSelect((this.element as HTMLSelectElement), { // eslint-disable-line no-new
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
    console.log(query)
    const url = '/models.manyfold_api_v0?q=' + encodeURIComponent(query)
    fetch(url)
      .then(async response => await response.json())
      .then(json => {
        const items = json.member.map((it) => ({ id: it['@id'].split('/').pop(), name: it.name }))
        console.log(items)
        callback(items)
      }).catch(() => {
        callback()
      })
  }
}
