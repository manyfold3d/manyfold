import * as Comlink from 'comlink'
import 'src/comlink_event_handler'
import type { OffscreenRenderer } from 'offscreen_renderer'

export class ObjectPreview {
  progressBar: HTMLDivElement | null
  progressLabel: HTMLSpanElement | null
  canvas: HTMLCanvasElement
  renderer: any
  observer: IntersectionObserver | null
  loading: boolean = false

  constructor (canvas) {
    this.canvas = canvas
    this.progressBar = this.canvas.parentElement?.getElementsByClassName('progress-bar')[0] as HTMLDivElement
    this.progressLabel = this.canvas.parentElement?.getElementsByClassName('progress-label')[0] as HTMLSpanElement
  }

  async initialize (): Promise<void> {
    await this.initializeOffscreenRenderer();
    this.connectEvents();
  }

  async initializeOffscreenRenderer (): Promise<void> {
    if (this.canvas.dataset.workerUrl === undefined || this.canvas.dataset.workerUrl === null) {
      console.log('ERROR: Could not load worker!')
      return
    }
    // Create offscreen renderer worker
    const offscreenCanvas = this.canvas.transferControlToOffscreen()
    const RemoteOffscreenRenderer = await Comlink.wrap<typeof OffscreenRenderer>(
      new Worker(this.canvas.dataset.workerUrl, { type: 'module' })
    )
    this.renderer = await new RemoteOffscreenRenderer(
      Comlink.transfer(offscreenCanvas as unknown as HTMLCanvasElement, [offscreenCanvas]), { ...this.canvas.dataset }
    )
  }

  connect (): void {
    // Handle resize events
    window.addEventListener('resize', this.onResize.bind(this))
    this.onResize()
    // Handle interaction events
    const pointerEvents = ['pointerdown', 'pointermove', 'pointerup']
    pointerEvents.forEach((eventName) => {
      this.canvas.addEventListener(eventName, this.onPointerEvent.bind(this))
    })
    const keyEvents = ['keydown', 'keyup']
    keyEvents.forEach((eventName) => {
      this.canvas.addEventListener(eventName, this.onKeyEvent.bind(this))
    })
    const otherEvents = ['wheel', 'contextmenu']
    otherEvents.forEach((eventName) => {
      this.canvas.addEventListener(eventName, this.onEvent.bind(this))
    })
    // Monitor visibility
    this.observer = new window.IntersectionObserver(
      this.onIntersectionChanged.bind(this), {}
    )
    this.observer.observe(this.canvas)
    // Monitor load button click
    const loadButton = this.canvas.parentElement?.getElementsByClassName('object-preview-progress')[0] as HTMLDivElement
    loadButton.addEventListener('click', this.load.bind(this))
  }

  onIntersectionChanged (entries, observer): void {
    if ((this.canvas.dataset.autoLoad === 'true') && (entries[0].isIntersecting === true)) {
      this.load()
    }
  }

  onPointerEvent (event): void {
    if (event.type === 'pointerdown') {
      this.canvas.focus()
      this.canvas.setPointerCapture(event.pointerId)
    }
    this.onEvent(event)
  }

  onKeyEvent (event): void {
    if ([
      'ArrowUp',
      'ArrowDown',
      'ArrowLeft',
      'ArrowRight',
      'Minus',
      'Equal'
    ].includes(event.code)) {
      this.onEvent(event)
    }
  }

  onEvent (event): void {
    event.preventDefault()
    this.renderer.handleEvent(event)
  }

  onLoadProgress (percentage: number): void {
    if ((this.progressBar == null) || (this.progressLabel == null)) { return }
    if (percentage === 100) {
      this.progressLabel.textContent = window.i18n.t('renderer.processing')
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

  onResize (): void {
    this.renderer.onResize(
      this.canvas.clientWidth,
      this.canvas.clientHeight,
      window.devicePixelRatio
    )
  }

  load (): void {
    if (this.loading) { return }
    this.loading = true
    this.renderer.load(
      Comlink.proxy(this.onLoad.bind(this)),
      Comlink.proxy(this.onLoadProgress.bind(this)),
      Comlink.proxy(this.onLoadError.bind(this))
    )
  }
}
