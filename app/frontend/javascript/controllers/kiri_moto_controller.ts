import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="kiri-moto"
export default class extends Controller {
  static values = {
    url: String,
    origin: String
  }

  static targets = [
    'iframe'
  ]

  declare urlValue: string
  declare targetOrigin: string
  declare originValue: string
  declare iframeTarget: HTMLIFrameElement

  contentWindow: Window | null = null

  connect () {
    const parsed = new URL(this.iframeTarget.src)
    this.targetOrigin = `${parsed.protocol}//${parsed.hostname}`
    this.contentWindow = this.iframeTarget.contentWindow
    console.log('Waiting for frame load...')
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

  onFrameLoaded (event) {
    console.log('Connecting to Kiri:Moto...')
    const origin = new URL(this.originValue)
    this.send({ connect: `${origin.protocol}//${origin.hostname}` })
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
      case 'function.export':
      case 'export.done':
        this.onExportDone(event.data.data)
        break
      default:
        console.log('Unhandled message:')
        console.log(event)
    }
  }

  private

  onConnected (data) {
    console.log(`Kiri:Moto connected ${data}`)
    // Set up event subscriptions
    this.send({ event: 'function.export' })
    // Start loading file
    this.load()
  }

  onLoaded () {
    // Close progress box
    this.progress(0, '')
  }

  onExportDone (data) {
    console.log(data)
  }

  // Kiri:Moto frame connection code adapted to Typescript from https://grid.space/kiri/frame.html

  send (message) {
    this.contentWindow?.postMessage(message, this.targetOrigin)
  }

  // parse (data, type) { this.send({ parse: data, type }) }

  // get (scope) { this.send({ get: scope }) }

  // set (scope, data) { this.send({ set: scope, data }) }

  setMode (mode) { this.send({ mode }) }

  // setDevice (device) { this.send({ device }) }

  // setProcess (process) { this.send({ process }) }

  // setFeatures (features) { this.send({ features }) }

  // setController (controller) { this.send({ controller }) }

  progress (value, message) { this.send({ progress: value, message }) }

  // alert (alertValue, time) { this.send({ alert: alertValue, time }) }

  // emit (emitValue, message) { this.send({ emit: emitValue, message }) }
}
