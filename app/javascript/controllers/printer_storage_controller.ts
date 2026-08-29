import { Controller } from '@hotwired/stimulus'

// Auto-submit storage upload when a sliced file is chosen.
export default class extends Controller {
  static targets = ['fileInput']

  declare readonly fileInputTarget: HTMLInputElement
  declare readonly hasFileInputTarget: boolean

  submitUpload (event: Event): void {
    const input = event.currentTarget as HTMLInputElement
    if (input.files == null || input.files.length === 0) return
    const form = input.closest('form')
    form?.requestSubmit()
  }
}
