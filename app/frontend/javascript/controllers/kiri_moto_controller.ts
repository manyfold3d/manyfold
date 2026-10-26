import { Controller } from '@hotwired/stimulus'
import * as tus from 'tus-js-client'

// Connects to data-controller="kiri-moto"
export default class extends Controller {
  static values = {
    url: String,
    uploadUrl: String,
    modelUrl: String,
    outputFilename: String,
    origin: String
  }

  static targets = [
    'iframe'
  ]

  declare urlValue: string
  declare uploadUrlValue: string
  declare modelUrlValue: string
  declare outputFilenameValue: string
  declare targetOrigin: string
  declare originValue: string
  declare iframeTarget: HTMLIFrameElement
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
  }

  onExportDone (data) {
    // Upload file to tus endpoint
    const blob = new Blob([data.file])
    const filename = `${this.outputFilenameValue}.${data.format}`

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

    fetch(this.modelUrlValue + '/model_files', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: formData.toString()
    })
  }

  send (message) {
    this.contentWindow?.postMessage(message, this.targetOrigin)
  }
}
