import { Controller } from '@hotwired/stimulus'
import * as tus from 'tus-js-client'

// Connects to data-controller="kiri-moto"
export default class extends Controller {
  static values = {
    url: String,
    uploadUrl: String,
    modelUrl: String,
    origin: String,
    sourceFileId: String,
  }

  static targets = [
    'iframe',
    'basename',
    'extension',
    'saveButton'
  ]

  declare urlValue: string
  declare uploadUrlValue: string
  declare modelUrlValue: string
  declare targetOrigin: string
  declare originValue: string
  declare sourceFileIdValue: string
  declare iframeTarget: HTMLIFrameElement
  declare basenameTarget: HTMLInputElement
  declare extensionTarget: HTMLSpanElement
  declare saveButtonTarget: HTMLButtonElement
  declare connected: boolean
  declare uploader

  contentWindow: Window | null = null

  connect () {
    const parsed = new URL(this.iframeTarget.src)
    this.targetOrigin = `${parsed.protocol}//${parsed.hostname}`
    this.contentWindow = this.iframeTarget.contentWindow
    this.connected = false
    this.connectToKiriMoto()
  }

  load () {
    this.send({ event: 'device.selected' }) // Subscribe to device change events
    this.send({
      clear: 'true',
      progress: 0.01,
      message: 'initializing',
    })
    this.send({
      load: this.urlValue,
      progress: 0.02,
      message: 'loading'
    })
  }

  export () {
    this.saveButtonTarget.disabled = true
    this.send({ function: 'export', callback: true })
  }

  onMessage (event) {
    if (event.origin !== this.targetOrigin) {
      return
    }
    switch (event.data.event) {
      case 'connected':
        this.onConnected(event.data.data)
        break
      case 'loaded':
        this.onLoaded()
        break
      case 'export.done':
        this.onExportDone(event.data.data)
        break
      case 'device.selected':
        this.onDeviceChanged(event.data.data)
        break
      default:
        console.log('Unhandled message:')
        console.log(event)
    }
  }

  private

  connectToKiriMoto () {
    if (!this.connected) {
      console.log('Connecting to Kiri:Moto...')
      const origin = new URL(this.originValue)
      this.send({
        connect: `${origin.protocol}//${origin.hostname}`
      })
      window.setTimeout(this.connectToKiriMoto.bind(this), 1000)
    }
  }

  onConnected (data) {
    this.connected = true
    console.log(`Kiri:Moto connected ${data}`)
    // Start loading file
    this.load()
  }

  onLoaded () {
    // Close progress box
    this.send({ progress: 0 })
    // Enable save button
    this.saveButtonTarget.disabled = false
  }

  onExportDone (data) {
    // Upload file to tus endpoint
    const blob = new Blob([data.file])
    const filename = `${this.basenameTarget.value}.${data.format}`

    this.uploader = new tus.Upload(blob, {
      endpoint: this.uploadUrlValue,
      retryDelays: [0, 3000, 5000, 10000, 20000],
      metadata: {
        filename
      },
      onError: this.onUploadError.bind(this),
      onProgress: this.onUploadProgress.bind(this),
      onSuccess: this.onUploadComplete.bind(this),
    })

    // Check if there are any previous uploads to continue.
    this.uploader.findPreviousUploads().then(function (previousUploads) {
      // Found previous uploads so we select the first one.
      if (previousUploads.length) {
        this.uploader.resumeFromPreviousUpload(previousUploads[0])
      }
      // Start the upload
      this.uploader.start()
    }.bind(this))
  }

  onDeviceChanged (data) {
    this.extensionTarget.textContent = `.${data.slaFileExt || data.gcodeFExt}`
  }

  onUploadError (error) {
    console.log('Upload failed: ' + error)
  }

  onUploadProgress (bytesUploaded, bytesTotal) {
    const percentage = ((bytesUploaded / bytesTotal) * 100).toFixed(2)
    console.log(bytesUploaded, bytesTotal, percentage + '%')
  }

  onUploadComplete () {
    const formData = new URLSearchParams()
    formData.append('model[file][0][id]', this.uploader.url)
    formData.append('model[file][0][name]', this.uploader.options.metadata.filename)
    formData.append('model[file][0][relationships_attributes][0][objekt_id]', this.sourceFileIdValue)
    formData.append('model[file][0][relationships_attributes][0][predicate]', 'alternative_format_of')

    fetch(this.modelUrlValue + '/model_files', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: formData.toString()
    }).then(response => {
      window.location.href = response.url
    })
  }

  send (message) {
    this.contentWindow?.postMessage(message, this.targetOrigin)
  }
}
