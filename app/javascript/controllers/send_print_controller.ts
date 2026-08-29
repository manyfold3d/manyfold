import { Controller } from '@hotwired/stimulus'

// Gates the sliced-file send form against send_eligibility JSON (REQ-004).
export default class extends Controller {
  static targets = ['printer', 'reasons', 'form', 'submit', 'csrf']
  static values = {
    eligibilityUrl: String,
    modelId: String,
    fileId: String
  }

  declare readonly printerTarget: HTMLSelectElement
  declare readonly reasonsTarget: HTMLElement
  declare readonly formTarget: HTMLFormElement
  declare readonly submitTarget: HTMLButtonElement
  declare readonly csrfTarget: HTMLInputElement
  declare readonly hasCsrfTarget: boolean
  declare readonly eligibilityUrlValue: string
  declare readonly modelIdValue: string
  declare readonly fileIdValue: string

  connect (): void {
    if (this.hasCsrfTarget) {
      const meta = document.querySelector('meta[name="csrf-token"]')
      this.csrfTarget.value = meta?.getAttribute('content') ?? ''
    }
    void this.refreshEligibility()
  }

  async refreshEligibility (): Promise<void> {
    const printerId = this.printerTarget.value
    this.clearReasons()
    this.submitTarget.disabled = true
    this.formTarget.action = '#'

    if (printerId === '' || this.eligibilityUrlValue === '') return

    const url = new URL(this.eligibilityUrlValue, window.location.origin)
    url.searchParams.set('print_host_id', printerId)

    try {
      const response = await fetch(url.toString(), {
        headers: { Accept: 'application/json' },
        credentials: 'same-origin'
      })
      if (!response.ok) throw new Error(`eligibility ${response.status}`)
      const data = await response.json() as {
        eligible?: boolean
        offered?: boolean
        reasons?: Array<{ message?: string, code?: string }>
      }

      if (data.eligible === true && data.offered !== false) {
        this.formTarget.action = `/printers/${printerId}/send_file`
        this.submitTarget.disabled = false
      } else {
        this.showReasons(data.reasons ?? [{ message: 'Not eligible to send' }])
      }
    } catch (error) {
      this.showReasons([{ message: String(error) }])
    }
  }

  clearReasons (): void {
    this.reasonsTarget.innerHTML = ''
    this.reasonsTarget.classList.add('hidden')
  }

  showReasons (reasons: Array<{ message?: string, code?: string }>): void {
    this.reasonsTarget.innerHTML = ''
    for (const reason of reasons) {
      const li = document.createElement('li')
      li.textContent = reason.message ?? reason.code ?? 'blocked'
      this.reasonsTarget.appendChild(li)
    }
    this.reasonsTarget.classList.remove('hidden')
  }
}
