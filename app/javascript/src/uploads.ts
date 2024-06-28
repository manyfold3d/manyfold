import Uppy from '@uppy/core'
import Dashboard from '@uppy/dashboard'
import Form from '@uppy/form'
import XHR from '@uppy/xhr-upload'

document.addEventListener('DOMContentLoaded', () => {
	document.querySelectorAll('#uppy').forEach((element: HTMLDivElement) => {
		const settings = element.dataset
		new Uppy({
			autoProceed: true,
			restrictions: {
				allowedFileTypes: settings.allowedFileTypes?.split(","),
				maxFileSize: +(settings?.maxFileSize || -1)
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
				target: element.closest('form') || undefined,
				getMetaFromForm: false,
				resultName: "uploads"
			})
			.use(XHR, { endpoint: '/upload' })
	})
})
