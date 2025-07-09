import { Controller } from '@hotwired/stimulus'

import Uppy from '@uppy/core'
import Dashboard from '@uppy/dashboard'
import Tus from '@uppy/tus'
import Url from '@uppy/url'

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

  connect (): void {
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
      .use(Url, { companionUrl: '/uppy_companion/' })
      .use(Tus, {
        endpoint: settings.uploadEndpoint ?? '/upload',
        chunkSize: 1 * 1024 * 1024
      })
    const submitButton = this.element?.closest('form')?.querySelector("input[type='submit']")
    this.uppy.on('upload', () => {
      submitButton?.setAttribute('disabled', 'disabled')
    })
    this.uppy.on('complete', (result) => {
      if (result.successful?.length != null && result.successful.length > 0) {
        submitButton?.removeAttribute('disabled')
      }
    })
    this.element.closest('form')?.addEventListener('formdata', (event) => {
      this.uppy?.getFiles().forEach((f, index) => {
        if (f.tus?.uploadUrl != null) {
          event.formData.set(`file[${index}][id]`, f.tus?.uploadUrl)
          if (f.name != null) { event.formData.set(`file[${index}][name]`, f.name) }
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
}
