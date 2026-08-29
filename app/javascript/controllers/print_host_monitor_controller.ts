import { Controller } from '@hotwired/stimulus'

/**
 * After snapshot 5xx/network error, wait at least this many ms (and at least
 * `interval`) before the next snapshot attempt. INIT-009/SPEC-003 REQ-003.
 */
export const SNAPSHOT_ERROR_BACKOFF_MS = 5000

// Polls SDCP status JSON and refreshes the authenticated camera snapshot.
// Updates structured telemetry targets when present (Print Studio monitor).
// Single-flight snapshot + error backoff + hidden-tab pause (INIT-009/SPEC-003).
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
  #snapshotInFlight = false
  #snapshotBackoffUntil = 0
  #objectUrl?: string
  readonly #onVisibilityChange = (): void => { this.handleVisibilityChange() }

  connect (): void {
    document.addEventListener('visibilitychange', this.#onVisibilityChange)
    if (!document.hidden) this.startPolling()
  }

  disconnect (): void {
    document.removeEventListener('visibilitychange', this.#onVisibilityChange)
    this.stopPolling()
    this.revokeObjectUrl()
  }

  handleVisibilityChange (): void {
    if (document.visibilityState === 'hidden') {
      this.stopPolling()
      return
    }
    this.startPolling()
  }

  startPolling (): void {
    if (this.#timer != null) return
    void this.refresh()
    this.#timer = window.setInterval(() => { void this.refresh() }, this.intervalValue)
  }

  stopPolling (): void {
    if (this.#timer == null) return
    window.clearInterval(this.#timer)
    this.#timer = undefined
  }

  async refresh (): Promise<void> {
    if (document.visibilityState === 'hidden') return
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
    // Single-flight: interval ticks must not stack overlapping snapshot loads.
    if (this.#snapshotInFlight) return
    if (Date.now() < this.#snapshotBackoffUntil) return

    this.#snapshotInFlight = true
    const url = `${this.snapshotUrlValue}${this.snapshotUrlValue.includes('?') ? '&' : '?'}t=${Date.now()}`
    try {
      // Fetch blob so 5xx is detectable (img.src alone does not expose status).
      const response = await fetch(url, {
        credentials: 'same-origin',
        headers: { Accept: 'image/jpeg,image/*,*/*' }
      })
      if (!response.ok) {
        this.armSnapshotBackoff()
        return
      }
      const blob = await response.blob()
      if (blob.size <= 100) {
        this.armSnapshotBackoff()
        return
      }
      const objectUrl = URL.createObjectURL(blob)
      this.revokeObjectUrl()
      this.#objectUrl = objectUrl
      this.snapshotTarget.src = objectUrl
      try {
        await this.snapshotTarget.decode()
      } catch {
        this.armSnapshotBackoff()
      }
    } catch {
      this.armSnapshotBackoff()
    } finally {
      this.#snapshotInFlight = false
    }
  }

  /** Schedule next snapshot no sooner than max(interval, SNAPSHOT_ERROR_BACKOFF_MS). */
  armSnapshotBackoff (): void {
    const delay = Math.max(this.intervalValue, SNAPSHOT_ERROR_BACKOFF_MS)
    this.#snapshotBackoffUntil = Date.now() + delay
  }

  revokeObjectUrl (): void {
    if (this.#objectUrl == null) return
    URL.revokeObjectURL(this.#objectUrl)
    this.#objectUrl = undefined
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
