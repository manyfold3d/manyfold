import Uppy from '@uppy/core'
import Dashboard from '@uppy/dashboard'
import Tus from '@uppy/tus'
import Url from '@uppy/url'

import en from '@uppy/locales/lib/en_US'
import fr from '@uppy/locales/lib/fr_FR'
import de from '@uppy/locales/lib/de_DE'
import pl from '@uppy/locales/lib/pl_PL'

const uppyLocales = { en, de, fr, pl }

document.addEventListener('ManyfoldReady', () => {
  document.querySelectorAll('#uppy').forEach((element: HTMLDivElement) => {
    const settings = element.dataset
    const uppy = new Uppy({
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
      .use(Url, { companionUrl: '/' })
      .use(Tus, {
        endpoint: settings.uploadEndpoint ?? '/upload',
        chunkSize: 5 * 1024 * 1024
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
      const uploads = uppy.getFiles().map((f) => {
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
