import { Controller } from '@hotwired/stimulus'
import f3d from 'f3d'

// Connects to data-controller="f3d-renderer"
export default class extends Controller {
  engine: any
  progressBar: HTMLDivElement | null
  progressLabel: HTMLSpanElement | null

  connect (): void {
    this.progressBar = this.element.parentElement?.getElementsByClassName('progress-bar')[0] as HTMLDivElement
    this.progressLabel = this.element.parentElement?.getElementsByClassName('progress-label')[0] as HTMLSpanElement
    const loadButton = this.element.parentElement?.getElementsByClassName('object-preview-progress')[0] as HTMLDivElement
    loadButton.addEventListener('click', this.load.bind(this))
  }

  async init (data: Uint8Array): Promise<void> {
    const settings = {
      canvas: this.element
    }
    await f3d(settings).then(async (F3D) => {
      this.progressBar?.parentElement?.remove()
      this.progressBar = null
      this.progressLabel = null

      F3D.Engine.autoloadPlugins()
      // Uncomment this to get an updated list of formats in dev
      // console.log(`F3D supported types: ${F3D.Engine.getReadersInfo().map((reader) => (`${reader["extensions"][0]}: ${reader["mimeTypes"][0]}`)).flat()}`);
      this.engine = F3D.Engine.create()
      const options = this.engine.getOptions()
      // background must be set to black for proper blending with transparent canvas
      options.setAsString('render.background.color', '#000000')

      // make it look nice
      options.toggle('render.effect.antialiasing.enable')
      options.toggle('render.effect.tone_mapping')
      options.toggle('render.effect.ambient_occlusion')

      options.toggle('scene.animation.autoplay', true)

      // display widgets
      options.toggle('render.grid.enable', true)
      options.setAsString('render.grid.color', '#00ffff')
      options.setAsString('render.grid.subdivisions', '0')
      options.setAsString('render.grid.unit', '10')

      // default to +Z
      options.setAsString('scene.up_direction', '+Z')

      const canvas = this.element
      const scale = window.devicePixelRatio
      console.log(scale * canvas.clientWidth)
      console.log(scale * canvas.clientHeight)
      this.engine.getWindow().setSize(scale * canvas.clientWidth, scale * canvas.clientHeight)

      const scene = this.engine.getScene()
      scene.clear()
      try {
        scene.addBuffer(data)
      } catch (e) {
        console.log('Unsupported file')
      }

      const camera = this.engine.getWindow().getCamera()
      const foc = camera.focalPoint
      const dir = [-1, 1, -0.5]
      const pos = [0, 0, 0]
      for (let i = 0; i < 3; i++) {
        pos[i] = foc[i] - dir[i]
      }
      camera.position = pos
      camera.resetToBounds(0.9)
      this.engine.getWindow().render()
      this.engine.getInteractor().start()
    })
  }

  async load (): Promise<void> {
    const url = (this.element as HTMLCanvasElement).dataset.previewUrl
    if (url != null) {
      const xhr = new XMLHttpRequest()
      xhr.open('GET', url)
      xhr.responseType = 'arraybuffer'
      xhr.addEventListener('progress', this.onLoadProgress.bind(this))
      xhr.addEventListener('error', this.onLoadError.bind(this))
      xhr.onreadystatechange = function () {
        if (xhr.readyState === XMLHttpRequest.DONE) {
          this.init(new Uint8Array(xhr.response))
        }
      }.bind(this)
      xhr.send()
    }
  }

  onLoadProgress (event): void {
    const percentage = Math.round((event.loaded / event.total) * 100)
    if ((this.progressBar == null) || (this.progressLabel == null)) { return }
    if (percentage === 100) {
      this.progressLabel.textContent = window.i18n.t('renderer.processing') // i18n-tasks-use t('renderer.processing')
    } else {
      this.progressLabel.textContent = `${percentage}%`
    }
    this.progressBar.style.width = `${percentage}%`
    this.progressBar.ariaValueNow = percentage.toString()
  }

  onLoadError (): void {
    if ((this.progressBar == null) || (this.progressLabel == null)) { return }
    this.progressBar.classList.add('bg-danger')
    this.progressBar.style.width = this.progressBar.ariaValueNow = '100%'
    this.progressLabel.textContent = window.i18n.t('renderer.errors.load') // i18n-tasks-use t('renderer.errors.load')
  }
}
