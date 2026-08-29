import { Controller } from '@hotwired/stimulus'

// Polls the queue JSON board and refreshes live printing card telemetry.
export default class extends Controller {
  static targets = ['card', 'layers', 'percent', 'bar', 'elapsed', 'remaining']
  static values = {
    url: String,
    interval: { type: Number, default: 5000 }
  }

  declare readonly cardTargets: HTMLElement[]
  declare readonly urlValue: string
  declare readonly intervalValue: number

  #timer?: number

  connect (): void {
    if (this.urlValue === '') return
    this.#timer = window.setInterval(() => { void this.refresh() }, this.intervalValue)
  }

  disconnect (): void {
    if (this.#timer != null) window.clearInterval(this.#timer)
  }

  async refresh (): Promise<void> {
    try {
      const response = await fetch(this.urlValue, {
        headers: { Accept: 'application/json' },
        credentials: 'same-origin'
      })
      if (!response.ok) return
      const payload = await response.json() as {
        queue?: { printing?: Array<Record<string, unknown>> }
      }
      const printing = payload.queue?.printing ?? []
      for (const job of printing) {
        this.applyJob(job)
      }
    } catch {
      // Keep last rendered HTML on transient poll errors.
    }
  }

  applyJob (job: Record<string, unknown>): void {
    const id = String(job.id ?? '')
    const card = this.cardTargets.find((el) => el.dataset.jobId === id && el.dataset.column === 'printing')
    if (card == null) return

    const current = Number(job.current_layer ?? 0)
    const total = Number(job.layer_count ?? 0)
    const pct = total > 0 ? Math.min(100, Math.round((current / total) * 100)) : 0

    const layers = card.querySelector<HTMLElement>('[data-print-queue-target="layers"]')
    if (layers != null && total > 0) {
      layers.textContent = `Layer ${current.toLocaleString()} / ${total.toLocaleString()}`
    }

    const percent = card.querySelector<HTMLElement>('[data-print-queue-target="percent"]')
    if (percent != null) percent.textContent = `${pct}%`

    const bar = card.querySelector<HTMLElement>('[data-print-queue-target="bar"]')
    if (bar != null) bar.style.width = `${pct}%`

    const startedAt = job.started_at != null ? Date.parse(String(job.started_at)) : NaN
    const estimated = Number(job.estimated_duration_seconds ?? 0)
    if (!Number.isNaN(startedAt)) {
      const elapsedSec = Math.max(0, Math.floor((Date.now() - startedAt) / 1000))
      const elapsed = card.querySelector<HTMLElement>('[data-print-queue-target="elapsed"]')
      if (elapsed != null) elapsed.textContent = this.formatDuration(elapsedSec)
      if (estimated > 0) {
        const remaining = card.querySelector<HTMLElement>('[data-print-queue-target="remaining"]')
        if (remaining != null) {
          remaining.textContent = this.formatDuration(Math.max(0, estimated - elapsedSec))
        }
      }
    }
  }

  formatDuration (seconds: number): string {
    const hours = Math.floor(seconds / 3600)
    const mins = Math.floor((seconds % 3600) / 60)
    return `${String(hours).padStart(2, '0')}h ${String(mins).padStart(2, '0')}m`
  }
}
