import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="kiri-moto"
export default class extends Controller {
  static values = {
    url: String
  }

  declare urlValue: string
  declare targetOrigin: string

  contentWindow: Window | null = null

  connect () {
    const parsed = new URL(this.element.src)
    this.targetOrigin = `${parsed.protocol}//${parsed.hostname}`
    this.contentWindow = (this.element as HTMLIFrameElement).contentWindow
    console.log('Connecting to Kiri:Moto...')
    this.send({ connect: 'https://floppy.ngrok.pizza' })
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

  slice () {
    this.send({ function: 'slice', callback: true })
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
      case 'slice.done':
        this.onSliceDone()
        break
      case 'prepare.done':
        this.onPrepareDone()
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

  onConnected (data) {
    console.log(`Kiri:Moto connected ${data}`)
    this.load()
  }

  onLoaded () {
    // Close progress box
    this.progress(0, '')
    this.slice()
  }

  onSliceDone () {
    this.export()
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
