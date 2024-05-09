import { EventDispatcher } from 'three'

export class CanvasProxy extends EventDispatcher {
  style = { touchAction: '' }
  clientWidth: number = 100
  clientHeight: number = 100
  left: number = 0
  top: number = 0
  realCanvas: HTMLCanvasElement

  ownerDocument = this

  constructor (canvas: HTMLCanvasElement) {
    super()
    this.realCanvas = canvas
  }

  getBoundingClientRect () {
    return {
      left: this.left,
      top: this.top,
      width: this.clientWidth,
      height: this.clientHeight,
      right: this.left + this.clientWidth,
      bottom: this.top + this.clientHeight,
    };
  }

  resize (left, top, width, height): void {
    this.left = left
    this.top = top
    this.clientWidth = width
    this.clientHeight = height
    this.realCanvas.width = width
    this.realCanvas.height = height
  }

  handleEvent (event): void {
    event.preventDefault = function () { }
    this.dispatchEvent(event)
  }

  // Pretend we can handle capture events
  getRootNode (): CanvasProxy {
    return this
  }

  setPointerCapture (): void {}
  releasePointerCapture (): void {}
}
