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
    this.progress(0.01, 'preparing')
    this.clear()
    this.progress(0.02, 'loading')
    this.load(this.urlValue)
  }

  onMessage (event) {
    switch (event.data.event) {
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
    }
  }

  private

  onLoaded () {
    // Close progress box
    this.progress(0, '')
    this.send({ function: 'slice', callback: true })
  }

  onSliceDone () {
    this.send({ function: 'prepare', callback: true })
  }

  onPrepareDone () {
    this.send({ function: 'export', callback: true })
  }

  onExportDone (data) {
    console.log(data)
  }

  // Kiri:Moto frame connection code adapted to Typescript from https://grid.space/kiri/frame.html

  send (message) {
    this.contentWindow?.postMessage(message, this.targetOrigin)
  }

  load (message) { this.send({ load: message }) }

  clear () { this.send({ clear: true }) }

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
