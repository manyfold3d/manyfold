import { Controller } from '@hotwired/stimulus'

// LAN UDP discover for Add Printer / Fleet discover card.
export default class extends Controller {
  static targets = ['results', 'button']
  static values = { url: String }

  declare readonly resultsTarget: HTMLElement
  declare readonly hasResultsTarget: boolean
  declare readonly buttonTarget: HTMLButtonElement
  declare readonly hasButtonTarget: boolean
  declare readonly urlValue: string

  async scan (event?: Event): Promise<void> {
    event?.preventDefault()
    if (this.urlValue === '') return

    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
      this.buttonTarget.textContent = this.buttonTarget.dataset.scanningLabel ?? 'Scanning…'
    }

    try {
      const token = this.csrfToken()
      const response = await fetch(this.urlValue, {
        method: 'POST',
        credentials: 'same-origin',
        headers: {
          Accept: 'text/vnd.turbo-stream.html, text/html',
          'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
          'X-CSRF-Token': token
        },
        body: new URLSearchParams({ authenticity_token: token }).toString()
      })
      if (!response.ok) throw new Error(`discover ${response.status}`)
      const contentType = response.headers.get('content-type') ?? ''
      const body = await response.text()
      if (contentType.includes('turbo-stream') && window.Turbo != null) {
        window.Turbo.renderStreamMessage(body)
      } else if (this.hasResultsTarget) {
        this.resultsTarget.innerHTML = body
      }
    } catch (error) {
      if (this.hasResultsTarget) {
        this.resultsTarget.innerHTML = `<p class="text-sm text-danger">${String(error)}</p>`
      }
    } finally {
      if (this.hasButtonTarget) {
        this.buttonTarget.disabled = false
        this.buttonTarget.textContent = this.buttonTarget.dataset.idleLabel ?? 'Scan network'
      }
    }
  }

  csrfToken (): string {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta?.getAttribute('content') ?? ''
  }
}

declare global {
  interface Window {
    Turbo?: { renderStreamMessage: (message: string) => void }
  }
}
