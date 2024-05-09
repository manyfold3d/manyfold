import * as Comlink from 'comlink'
import 'src/comlink_event_handler'

class ObjectPreview {
  progressBar: HTMLDivElement | null
  progressLabel: HTMLSpanElement | null
  canvas: HTMLCanvasElement
  renderer: any

  constructor (canvas) {
    this.canvas = canvas
    this.progressBar = this.canvas.parentElement?.getElementsByClassName('progress-bar')[0] as HTMLDivElement
    this.progressLabel = this.canvas.parentElement?.getElementsByClassName('progress-label')[0] as HTMLSpanElement
  }

  async run () {
    // Create offscreen renderer worker
    const offscreenCanvas = this.canvas.transferControlToOffscreen()
    const OffscreenRenderer = await Comlink.wrap(
      new Worker('/assets/offscreen_renderer.js', { type: 'module' })
    )
    this.renderer = await new OffscreenRenderer(
      Comlink.transfer(offscreenCanvas, [offscreenCanvas]), { ...this.canvas.dataset }
    )
    // Handle resize events
    window.addEventListener('resize', this.onResize.bind(this))
    this.onResize()
    // Handle interaction events
    const eventHandlers = [
      'pointerdown',
      'pointermove',
      'pointerup',
      'wheel',
      'keydown',
      'keyup',
      'contextmenu',
    ]
    eventHandlers.forEach((eventName) => {
      this.canvas.addEventListener(eventName, this.onEvent.bind(this))
    })
    // Autoload
    if (this.canvas.dataset.autoLoad === 'true') {
      this.load()
    }
  }

  onEvent (event) {
    event.preventDefault()
    if (event.type == "pointerdown") {
      this.canvas.setPointerCapture(event.pointerId)
    }
    this.renderer.handleEvent(event)
  }

  onLoadProgress (percentage: number): void {
    if ((this.progressBar == null) || (this.progressLabel == null)) { return }
    if (percentage === 100) {
      this.progressLabel.textContent = 'Reticulating splines...'
    } else {
      this.progressLabel.textContent = `${percentage}%`
    }
    this.progressBar.style.width = `${percentage}%`
    this.progressBar.ariaValueNow = percentage.toString()
  }

  onLoad (): void {
    this.progressBar?.parentElement?.remove()
    this.progressBar = null
    this.progressLabel = null
  }

  onLoadError (): void {
    if ((this.progressBar == null) || (this.progressLabel == null)) { return }
    this.progressBar?.classList.add('bg-danger')
    this.progressBar.style.width = this.progressBar.ariaValueNow = '100%'
    this.progressLabel.textContent = window.i18n.t('renderer.errors.load')
  }

  onResize () {
    this.renderer.onResize(
      this.canvas.left,
      this.canvas.top,
      this.canvas.clientWidth,
      this.canvas.clientHeight,
      window.devicePixelRatio
    )
  }

  load (): void {
    this.renderer.load(
      Comlink.proxy(this.onLoad.bind(this)),
      Comlink.proxy(this.onLoadProgress.bind(this)),
      Comlink.proxy(this.onLoadError.bind(this))
    )
  }

}

const preview_windows = []
document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('[data-preview]').forEach(async (canvas: HTMLCanvasElement) => {
    const preview = new ObjectPreview(canvas)
    preview_windows.push(preview)
    preview.run()
  })
})
