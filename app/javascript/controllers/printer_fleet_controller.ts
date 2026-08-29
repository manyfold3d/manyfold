import { Controller } from '@hotwired/stimulus'

// Fleet index: load per-printer status via JSON member (INIT-009/SPEC-004 · ADR D-2).
// HTML index must never sync-fetch SDCP; this controller owns online/offline after paint.
export default class extends Controller {
  static targets = [
    'badge', 'badgeDot', 'badgeLabel', 'summary', 'bar', 'eta',
    'snapshot', 'cameraOffline', 'liveBadge'
  ]

  static values = {
    statusUrl: String,
    labels: Object
  }

  declare readonly badgeTarget: HTMLElement
  declare readonly hasBadgeTarget: boolean
  declare readonly badgeDotTarget: HTMLElement
  declare readonly hasBadgeDotTarget: boolean
  declare readonly badgeLabelTarget: HTMLElement
  declare readonly hasBadgeLabelTarget: boolean
  declare readonly summaryTarget: HTMLElement
  declare readonly hasSummaryTarget: boolean
  declare readonly barTarget: HTMLElement
  declare readonly hasBarTarget: boolean
  declare readonly etaTarget: HTMLElement
  declare readonly hasEtaTarget: boolean
  declare readonly snapshotTarget: HTMLImageElement
  declare readonly hasSnapshotTarget: boolean
  declare readonly cameraOfflineTarget: HTMLElement
  declare readonly hasCameraOfflineTarget: boolean
  declare readonly liveBadgeTarget: HTMLElement
  declare readonly hasLiveBadgeTarget: boolean
  declare readonly statusUrlValue: string
  declare readonly labelsValue: Record<string, string>

  connect (): void {
    void this.refresh()
  }

  async refresh (): Promise<void> {
    if (this.statusUrlValue === '') return
    try {
      const response = await fetch(this.statusUrlValue, {
        headers: { Accept: 'application/json' },
        credentials: 'same-origin'
      })
      const payload = await response.json().catch(() => ({})) as Record<string, unknown>
      // Soft 502/{error} from Printers#status — do not throw opaque "status 502".
      if (!response.ok) {
        const err = payload.error != null ? String(payload.error) : `status ${response.status}`
        this.applyOffline(err)
        return
      }
      const data = (payload.status ?? payload) as Record<string, unknown>
      if (data.error != null || data.unsupported === true) {
        const errMsg = data.error != null ? String(data.error) : ''
        this.applyOffline(errMsg !== '' ? errMsg : this.label('offline'))
        return
      }
      this.applyOnline(data)
    } catch (error) {
      this.applyOffline(String(error))
    }
  }

  applyOffline (message: string): void {
    this.setBadge('offline')
    if (this.hasSummaryTarget) {
      this.summaryTarget.textContent = message !== '' ? message : this.label('offline')
      this.summaryTarget.classList.add('text-danger')
      this.summaryTarget.classList.remove('text-secondary-300')
    }
    if (this.hasBarTarget) this.barTarget.style.width = '0%'
    if (this.hasEtaTarget) this.etaTarget.textContent = this.label('offline_duration')
    // Camera is independent of SDCP status (go2rtc/RTSP). Hiding it here made
    // a status timeout look like a dead camera even when snapshots still work.
  }

  applyOnline (data: Record<string, unknown>): void {
    const printing = this.isPrinting(data)
    const paused = Number(data.print_status ?? 0) === 2
    const status = paused ? 'paused' : (printing ? 'printing' : 'idle')
    this.setBadge(status)

    const filename = data.filename != null ? String(data.filename) : ''
    const current = Number(data.current_layer ?? 0)
    const total = Number(data.total_layers ?? 0)
    const pct = total > 0 ? Math.round((current / total) * 100) : 0

    if (this.hasSummaryTarget) {
      this.summaryTarget.classList.remove('text-danger')
      this.summaryTarget.classList.add('text-secondary-300')
      if (printing && filename !== '') {
        this.summaryTarget.textContent = `${filename} · ${pct}% · Layer ${current}/${total}`
      } else if (printing) {
        this.summaryTarget.textContent = this.label('printing')
      } else {
        this.summaryTarget.textContent = this.label('no_active_job')
      }
    }

    if (this.hasBarTarget) this.barTarget.style.width = `${pct}%`

    if (this.hasEtaTarget) {
      if (!printing) {
        this.etaTarget.textContent = this.label('no_active_job')
      } else if (data.eta_seconds == null) {
        this.etaTarget.textContent = this.label('eta_unknown')
      } else {
        this.etaTarget.textContent = `${this.formatDuration(Number(data.eta_seconds))} remaining`
      }
    }

    // Camera visibility is owned by snapshotLoaded / snapshotFailed — not SDCP.
    this.setLiveBadge(printing)
  }

  setBadge (status: string): void {
    if (this.hasBadgeLabelTarget) {
      this.badgeLabelTarget.textContent = this.label(status)
    }
    if (this.hasBadgeTarget) {
      this.badgeTarget.className = this.badgeWrapperClass(status)
    }
    if (this.hasBadgeDotTarget) {
      this.badgeDotTarget.className = `size-1.5 rounded-full shrink-0 ${this.badgeDotClass(status)}`
    }
  }

  showCameraOffline (offline: boolean): void {
    if (this.hasCameraOfflineTarget) {
      this.cameraOfflineTarget.classList.toggle('hidden', !offline)
    }
    if (this.hasSnapshotTarget) {
      this.snapshotTarget.classList.toggle('hidden', offline)
    }
    if (this.hasLiveBadgeTarget) {
      this.liveBadgeTarget.classList.toggle('hidden', offline)
    }
  }

  /** img onerror — camera path failed independently of SDCP status. */
  snapshotFailed (): void {
    this.showCameraOffline(true)
  }

  /** img load — restore camera when a later refresh / navigation succeeds. */
  snapshotLoaded (): void {
    this.showCameraOffline(false)
  }

  setLiveBadge (printing: boolean): void {
    if (!this.hasLiveBadgeTarget) return
    if (printing) {
      this.liveBadgeTarget.innerHTML =
        '<span class="inline-flex items-center gap-1.5 bg-danger/20 text-danger text-[10px] font-mono font-semibold px-2 py-0.5 rounded">' +
        '<span class="size-1.5 rounded-full bg-danger" aria-hidden="true"></span>' +
        `${this.escapeHtml(this.label('live'))}</span>`
    } else {
      this.liveBadgeTarget.innerHTML =
        '<span class="inline-flex items-center bg-white/10 text-secondary-300 text-[10px] font-mono px-2 py-0.5 rounded">' +
        `${this.escapeHtml(this.label('standby'))}</span>`
    }
  }

  isPrinting (data: Record<string, unknown>): boolean {
    const current = data.current_layer
    const total = data.total_layers
    const filename = data.filename
    const hasLayers = current != null && total != null && Number(total) > 0
    return hasLayers || (filename != null && String(filename) !== '')
  }

  label (key: string): string {
    return this.labelsValue[key] ?? key
  }

  badgeWrapperClass (status: string): string {
    const base = 'inline-flex items-center gap-1.5 px-2 py-1 rounded text-[11px] font-medium'
    switch (status) {
      case 'printing':
        return `${base} bg-primary-50 text-success dark:bg-primary-950/40 dark:text-success`
      case 'paused':
        return `${base} bg-warning/20 text-warning`
      case 'unsupported':
        return `${base} bg-secondary-100 text-secondary-600 dark:bg-secondary-800 dark:text-secondary-400`
      case 'offline':
        return `${base} bg-secondary-100 text-secondary-500 dark:bg-secondary-800 dark:text-secondary-500`
      default:
        return `${base} bg-secondary-100 text-secondary-600 dark:bg-secondary-800 dark:text-secondary-400`
    }
  }

  badgeDotClass (status: string): string {
    switch (status) {
      case 'printing': return 'bg-success'
      case 'paused': return 'bg-warning'
      case 'offline':
      case 'unsupported': return 'bg-secondary-500'
      default: return 'bg-secondary-400'
    }
  }

  formatDuration (seconds: number): string {
    if (Number.isNaN(seconds) || seconds < 0) return '—'
    const hours = Math.floor(seconds / 3600)
    const mins = Math.floor((seconds % 3600) / 60)
    if (hours > 0) return `${hours}h ${mins}m`
    return `${mins}m`
  }

  escapeHtml (value: string): string {
    return value
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
  }
}
