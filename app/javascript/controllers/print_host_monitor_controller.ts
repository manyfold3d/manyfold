import { Controller } from '@hotwired/stimulus'

// Polls SDCP status JSON and refreshes the authenticated camera snapshot.
// Updates structured telemetry targets when present (Print Studio monitor).
export default class extends Controller {
  static targets = [
    'status', 'snapshot', 'badge', 'connection', 'filename', 'percent',
    'layers', 'bar', 'eta', 'resin', 'uv'
  ]

  static values = {
    statusUrl: String,
    snapshotUrl: String,
    interval: { type: Number, default: 5000 }
  }

  declare readonly statusTarget: HTMLElement
  declare readonly hasStatusTarget: boolean
  declare readonly snapshotTarget: HTMLImageElement
  declare readonly hasSnapshotTarget: boolean
  declare readonly hasBadgeTarget: boolean
  declare readonly badgeTarget: HTMLElement
  declare readonly hasConnectionTarget: boolean
  declare readonly connectionTarget: HTMLElement
  declare readonly hasFilenameTarget: boolean
  declare readonly filenameTarget: HTMLElement
  declare readonly hasPercentTarget: boolean
  declare readonly percentTarget: HTMLElement
  declare readonly hasLayersTarget: boolean
  declare readonly layersTarget: HTMLElement
  declare readonly hasBarTarget: boolean
  declare readonly barTarget: HTMLElement
  declare readonly hasEtaTarget: boolean
  declare readonly etaTarget: HTMLElement
  declare readonly hasResinTarget: boolean
  declare readonly resinTarget: HTMLElement
  declare readonly hasUvTarget: boolean
  declare readonly uvTarget: HTMLElement
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
    if (this.statusUrlValue === '') return
    try {
      const response = await fetch(this.statusUrlValue, {
        headers: { Accept: 'application/json' },
        credentials: 'same-origin'
      })
      if (!response.ok) throw new Error(`status ${response.status}`)
      const payload = await response.json()
      const data = payload.status ?? payload
      if (this.hasStatusTarget) {
        this.statusTarget.textContent = JSON.stringify(data, null, 2)
      }
      this.applyTelemetry(data)
      if (this.hasConnectionTarget) {
        this.connectionTarget.textContent = '● CONNECTED'
        this.connectionTarget.classList.remove('text-danger')
        this.connectionTarget.classList.add('text-success')
      }
    } catch (error) {
      if (this.hasStatusTarget) {
        this.statusTarget.textContent = `error: ${String(error)}`
      }
      if (this.hasConnectionTarget) {
        this.connectionTarget.textContent = '● OFFLINE'
        this.connectionTarget.classList.remove('text-success')
        this.connectionTarget.classList.add('text-danger')
      }
    }
  }

  async refreshSnapshot (): Promise<void> {
    if (!this.hasSnapshotTarget || this.snapshotUrlValue === '') return
    const url = `${this.snapshotUrlValue}${this.snapshotUrlValue.includes('?') ? '&' : '?'}t=${Date.now()}`
    this.snapshotTarget.src = url
  }

  applyTelemetry (data: Record<string, unknown>): void {
    if (data.error != null) {
      if (this.hasFilenameTarget) this.filenameTarget.textContent = '—'
      if (this.hasPercentTarget) this.percentTarget.textContent = '0%'
      if (this.hasLayersTarget) this.layersTarget.textContent = '—'
      if (this.hasBarTarget) this.barTarget.style.width = '0%'
      if (this.hasEtaTarget) this.etaTarget.textContent = '—'
      return
    }

    const filename = String(data.filename ?? '—')
    const current = Number(data.current_layer ?? 0)
    const total = Number(data.total_layers ?? 0)
    const pct = total > 0 ? Math.round((current / total) * 100) : 0
    const etaSeconds = data.eta_seconds != null ? Number(data.eta_seconds) : null

    if (this.hasFilenameTarget) this.filenameTarget.textContent = filename
    if (this.hasPercentTarget) this.percentTarget.textContent = `${pct}%`
    if (this.hasLayersTarget) {
      this.layersTarget.textContent = total > 0 ? `layer ${current} / ${total}` : '—'
    }
    if (this.hasBarTarget) this.barTarget.style.width = `${pct}%`
    if (this.hasEtaTarget) this.etaTarget.textContent = this.formatDuration(etaSeconds)
    if (this.hasResinTarget) {
      const resin = data.resin_ml ?? data.estimated_resin_ml
      this.resinTarget.textContent = resin != null ? `${String(resin)} ml` : '—'
    }
    if (this.hasUvTarget) {
      const temp = data.temp_uv_c
      this.uvTarget.textContent = temp != null ? `UV ${String(temp)}°C` : '—'
    }
  }

  formatDuration (seconds: number | null): string {
    if (seconds == null || Number.isNaN(seconds) || seconds < 0) return '—'
    const hours = Math.floor(seconds / 3600)
    const mins = Math.floor((seconds % 3600) / 60)
    if (hours > 0) return `${hours}h ${mins}m`
    return `${mins}m`
  }
}
