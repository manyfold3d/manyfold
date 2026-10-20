import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="kiri-moto"
export default class extends Controller {
  static values = {
    url: String
  }

  declare urlValue: string

  contentWindow: Window | null = null

  connect () {
    this.contentWindow = (this.element as HTMLIFrameElement).contentWindow
    this.clear()
    this.load(this.urlValue)
  }

  onMessage (event) {
    switch (event.data.event) {
    }
  }

  private

  // Kiri:Moto frame connection code adapted to Typescript from https://grid.space/kiri/frame.html

  send (message) {
    this.contentWindow?.postMessage(message, this.element.src)
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

  // slice () { this.send({ function: "slice", callback: true }) }

  // prepare () { this.send({ function: "prepare", callback: true }) }

  // export (cb) { this.send({ function: "export", callback: (cb ? true : false) }) }

  // onmessage () { }

  // progress (progressValue, message) { this.send({ progress: progressValue, message }) }

  // alert (alertValue, time) { this.send({ alert: alertValue, time }) }

  // emit (emitValue, message) { this.send({ emit: emitValue, message }) }

  // registerEvent (event, fn) {
  //   this.onevent[event] = fn
  //   this.send({ event })
  // }
}
