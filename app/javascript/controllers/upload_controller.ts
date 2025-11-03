import { Controller } from '@hotwired/stimulus'

import Uppy from '@uppy/core'
import Dashboard from '@uppy/dashboard'
import Tus from '@uppy/tus'

import cs from '@uppy/locales/lib/cs_CZ'
import de from '@uppy/locales/lib/de_DE'
import en from '@uppy/locales/lib/en_US'
import es from '@uppy/locales/lib/es_ES'
import fr from '@uppy/locales/lib/fr_FR'
import ja from '@uppy/locales/lib/ja_JP'
import nl from '@uppy/locales/lib/nl_NL'
import pl from '@uppy/locales/lib/pl_PL'

const uppyLocales = { cs, de, en, es, fr, ja, nl, pl }

// Connects to data-controller="upload"
export default class extends Controller {
  uppy: Uppy | null = null
  nameLabel: HTMLDivElement | null = null
  nameField: HTMLDivElement | null = null
  multiMessage: HTMLDivElement | null = null
  singleMessage: HTMLDivElement | null = null

  connect (): void {
    this.sweepLocalStorage()
    if (this.uppy != null) { return }
    const settings = (this.element as HTMLElement).dataset
    this.uppy = new Uppy({
      autoProceed: true,
      locale: uppyLocales[window.i18n.locale],
      restrictions: {
        allowedFileTypes: settings.allowedFileTypes?.split(','),
        maxFileSize: +(settings?.maxFileSize ?? -1)
      }
    })
      .use(Dashboard, {
        inline: true,
        target: this.element,
        theme: 'auto',
        width: '100%',
        height: '25rem',
        showRemoveButtonAfterComplete: true,
        hideProgressAfterFinish: true
      })
      .use(Tus, {
        endpoint: settings.uploadEndpoint ?? '/upload',
        chunkSize: 1 * 1024 * 1024
      })
    const submitButton = this.element?.closest('form')?.querySelector("input[type='submit']")
    const form = this.element?.closest('form')
    if (form != null) {
      this.nameLabel = form.querySelector("div:has(> label[for='model_name'])")
      this.nameField = form.querySelector("div:has(> div > input[name='model[name]'])")
      this.multiMessage = form.querySelector("div[id='multi-model-message']")
      this.singleMessage = form.querySelector("div[id='single-model-message']")
    }
    this.uppy.on('upload', () => {
      submitButton?.setAttribute('disabled', 'disabled')
    })
    this.uppy.on('complete', (result) => {
      if (result.successful?.length != null && result.successful.length > 0) {
        submitButton?.removeAttribute('disabled')
      }
    })
    this.uppy.on('file-added', this.updateResultingModelState.bind(this))
    this.uppy.on('file-removed', this.updateResultingModelState.bind(this))
    this.element.closest('form')?.addEventListener('formdata', (event) => {
      this.uppy?.getFiles().forEach((f, index) => {
        if (f.tus?.uploadUrl != null) {
          event.formData.set(`model[file][${index}][id]`, f.tus?.uploadUrl)
          if (f.name != null) { event.formData.set(`model[file][${index}][name]`, f.name) }
        }
      })
    })
  }

  disconnect (): void {
    this.uppy?.destroy()
    this.uppy = null
  }

  reconnect (): void {
    this.disconnect()
    this.connect()
  }

  updateResultingModelState (): void {
    if (this.uppy === null) { return }
    const extensions = new Set(this.uppy.getFiles().map((f) => f.extension))
    const archiveExtensions = new Set((this.element as HTMLElement).dataset.archiveExtensions?.split(','))
    const difference = new Set([...extensions].filter(value => !archiveExtensions.has(value)))
    if (difference.size > 0) { this.setSingleModelMode() } else { this.setMultiModelMode() }
  }

  setMultiModelMode (): void {
    if (this.nameLabel != null) { this.nameLabel.style.display = 'none' }
    if (this.nameField != null) { this.nameField.style.display = 'none' }
    if (this.multiMessage != null) { this.multiMessage.style.display = 'block' }
    if (this.singleMessage != null) { this.singleMessage.style.display = 'none' }
  }

  setSingleModelMode (): void {
    if (this.nameLabel != null) { this.nameLabel.style.display = 'block' }
    if (this.nameField != null) { this.nameField.style.display = 'block' }
    if (this.multiMessage != null) { this.multiMessage.style.display = 'none' }
    if (this.singleMessage != null) { this.singleMessage.style.display = 'block' }
  }

  sweepLocalStorage (): void {
    // Remove upload records older than 12 hours. Cache sweep is 6 hours, so after 12, the upstream file
    // is definitely gone and there's no point having the local record.
    const cutoff = Date.now() - (12 * 60 * 60 * 1000)
    // Get all the localStorage upload records
    const keys = Object.keys(localStorage).filter((x) => x.startsWith('tus::tus-uppy'))
    for (const key of keys) {
      const value = localStorage.getItem(key)
      if (value != null) {
        if (Date.parse(JSON.parse(value).creationTime) < cutoff) {
          localStorage.removeItem(key)
        }
      }
    }
  }
}
