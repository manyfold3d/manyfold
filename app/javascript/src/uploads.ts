import Uppy from '@uppy/core'
import Dashboard from '@uppy/dashboard'
import Form from '@uppy/form'
import XHR from '@uppy/xhr-upload'

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
      .use(Form, {
        target: element.closest('form') ?? undefined,
        getMetaFromForm: false,
        resultName: 'uploads'
      })
      .use(XHR, { endpoint: '/upload' })
    const submitButton = element?.closest('form')?.querySelector("input[type='submit']")
    uppy.on('upload', () => {
      submitButton?.setAttribute('disabled', 'disabled')
    })
    uppy.on('complete', (result) => {
      if (result.successful.length > 0) {
        submitButton?.removeAttribute('disabled')
      }
    })
  })
})
