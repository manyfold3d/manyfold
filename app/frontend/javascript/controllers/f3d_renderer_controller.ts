import { Controller } from '@hotwired/stimulus'
import f3d from 'f3d'

// Connects to data-controller="f3d-renderer"
export default class extends Controller {

  engine: any;

  async init (data: Uint8Array): Promise<void> {
    const settings = {
      canvas: this.element,
    };
    f3d(settings).then(async (F3D) => {
      F3D.Engine.autoloadPlugins();
      this.engine = F3D.Engine.create();
      const options = this.engine.getOptions();
      // background must be set to black for proper blending with transparent canvas
      options.setAsString("render.background.color", "#555555");

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

  async onLoad () {
    const url = this.element.dataset.previewUrl;
    try {
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`Response status: ${response.status}`);
      }

      const result = await response.bytes();
      this.init(result);
    } catch (error) {
      console.error(error.message);
    }
  }
}
