import { Controller } from '@hotwired/stimulus'

// Polls SDCP status JSON and refreshes the authenticated camera snapshot.
export default class extends Controller {
  static targets = ['status', 'snapshot']
  static values = {
    statusUrl: String,
    snapshotUrl: String,
    interval: { type: Number, default: 5000 }
  }

  declare readonly statusTarget: HTMLElement
  declare readonly hasStatusTarget: boolean
  declare readonly snapshotTarget: HTMLImageElement
  declare readonly hasSnapshotTarget: boolean
  declare readonly statusUrlValue: string
  declare readonly snapshotUrlValue: string
  declare readonly intervalValue: number

  #timer?: number

  connect (): void {
    void this.refresh()
    this.#timer = window.setInterval(() => { void this.refresh() }, this.intervalValue)
  }

  disconnect (): void {
    if (this.#timer != null) window.clearInterval(this.#timer)
  }

  async refresh (): Promise<void> {
    await Promise.all([this.refreshStatus(), this.refreshSnapshot()])
  }

  async refreshStatus (): Promise<void> {
    if (!this.hasStatusTarget || !this.statusUrlValue) return
    try {
      const response = await fetch(this.statusUrlValue, {
        headers: { Accept: 'application/json' },
        credentials: 'same-origin'
      })
      if (!response.ok) throw new Error(`status ${response.status}`)
      const data = await response.json()
      this.statusTarget.textContent = JSON.stringify(data, null, 2)
    } catch (error) {
      this.statusTarget.textContent = `error: ${String(error)}`
    }
  }

  async refreshSnapshot (): Promise<void> {
    if (!this.hasSnapshotTarget || !this.snapshotUrlValue) return
    const url = `${this.snapshotUrlValue}${this.snapshotUrlValue.includes('?') ? '&' : '?'}t=${Date.now()}`
    this.snapshotTarget.src = url
  }
}
