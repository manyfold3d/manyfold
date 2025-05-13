import Uppy from '@uppy/core'
import Dashboard from '@uppy/dashboard'
import Tus from '@uppy/tus'

import cs from '@uppy/locales/lib/cs_CZ'
import de from '@uppy/locales/lib/de_DE'
import en from '@uppy/locales/lib/en_US'
import es from '@uppy/locales/lib/es_ES'
import fr from '@uppy/locales/lib/fr_FR'
import nl from '@uppy/locales/lib/nl_NL'
import pl from '@uppy/locales/lib/pl_PL'

const uppyLocales = { cs, de, en, es, fr, nl, pl }

let uppy: Uppy | null = null

document.addEventListener('ManyfoldReady', () => {
  document.querySelectorAll('#uppy').forEach((element: HTMLDivElement) => {
    if (uppy != null) { return }
    const settings = element.dataset
    uppy = new Uppy({
      autoProceed: true,
      locale: uppyLocales[window.i18n.locale],
      restrictions: {
        allowedFileTypes: settings.allowedFileTypes?.split(','),
        maxFileSize: +(settings?.maxFileSize ?? -1)
      }
    })
      .use(Dashboard, {
        inline: true,
        target: `#${element.id}`,
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
    const submitButton = element?.closest('form')?.querySelector("input[type='submit']")
    uppy.on('upload', () => {
      submitButton?.setAttribute('disabled', 'disabled')
    })
    uppy.on('complete', (result) => {
      if (result.successful?.length != null && result.successful.length > 0) {
        submitButton?.removeAttribute('disabled')
      }
    })
    element.closest('form')?.addEventListener('formdata', (event) => {
      const uploads = uppy?.getFiles().map((f) => {
        return {
          id: f.tus?.uploadUrl,
          storage: 'cache',
          metadata: {
            filename: f.name,
            size: f.size,
            mime_type: f.type
          }
        }
      })
      event.formData.set('uploads', JSON.stringify(uploads))
    })
  })
})
