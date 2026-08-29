import { Controller } from '@hotwired/stimulus'

// Camera stream toggle + snapshot interval for printer settings (client-side).
export default class extends Controller {
  static targets = [
    'toggle', 'toggleKnob', 'interval', 'snapshot',
    'identityField', 'identityActions', 'editToggle'
  ]

  declare readonly toggleTarget: HTMLButtonElement
  declare readonly hasToggleTarget: boolean
  declare readonly toggleKnobTarget: HTMLElement
  declare readonly hasToggleKnobTarget: boolean
  declare readonly intervalTarget: HTMLSelectElement
  declare readonly hasIntervalTarget: boolean
  declare readonly snapshotTarget: HTMLImageElement
  declare readonly hasSnapshotTarget: boolean
  declare readonly identityActionsTarget: HTMLElement
  declare readonly hasIdentityActionsTarget: boolean
  declare readonly identityFieldTargets: HTMLInputElement[]
  declare readonly editToggleTarget: HTMLButtonElement
  declare readonly hasEditToggleTarget: boolean

  #streamEnabled = true
  #editing = false

  connect (): void {
    this.applyIdentityReadonly(true)
  }

  toggleStream (): void {
    this.#streamEnabled = !this.#streamEnabled
    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute('aria-checked', String(this.#streamEnabled))
      this.toggleTarget.classList.toggle('bg-primary-600', this.#streamEnabled)
      this.toggleTarget.classList.toggle('bg-secondary-600', !this.#streamEnabled)
    }
    if (this.hasToggleKnobTarget) {
      this.toggleKnobTarget.classList.toggle('translate-x-5', this.#streamEnabled)
      this.toggleKnobTarget.classList.toggle('translate-x-0', !this.#streamEnabled)
    }
    if (this.hasSnapshotTarget) {
      this.snapshotTarget.classList.toggle('opacity-40', !this.#streamEnabled)
    }
    this.syncMonitorInterval()
  }

  changeInterval (): void {
    this.syncMonitorInterval()
  }

  toggleIdentity (): void {
    this.#editing = !this.#editing
    this.applyIdentityReadonly(!this.#editing)
    if (this.hasIdentityActionsTarget) {
      this.identityActionsTarget.classList.toggle('hidden', !this.#editing)
    }
    if (this.hasEditToggleTarget) {
      const editingLabel = this.editToggleTarget.dataset.editingLabel ?? 'Cancel'
      const idleLabel = this.editToggleTarget.dataset.idleLabel ?? 'Edit configuration'
      this.editToggleTarget.textContent = this.#editing ? editingLabel : idleLabel
    }
  }

  applyIdentityReadonly (readonly: boolean): void {
    for (const field of this.identityFieldTargets) {
      field.readOnly = readonly
      field.classList.toggle('opacity-80', readonly)
    }
  }

  syncMonitorInterval (): void {
    const root = this.element as HTMLElement
    if (!this.#streamEnabled) {
      root.dataset.printHostMonitorIntervalValue = '3600000'
    } else {
      const ms = this.hasIntervalTarget ? this.intervalTarget.value : '10000'
      root.dataset.printHostMonitorIntervalValue = ms
    }
    const monitor = this.application.getControllerForElementAndIdentifier(root, 'print-host-monitor') as
      | { disconnect: () => void, connect: () => void }
      | null
    if (monitor != null) {
      monitor.disconnect()
      monitor.connect()
    }
  }
}
