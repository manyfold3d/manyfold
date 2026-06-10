import { Controller } from '@hotwired/stimulus'
import f3d from 'f3d'

// Connects to data-controller="f3d-renderer"
export default class extends Controller {
  init (data: Uint8Array): void {
    const settings = {
      canvas: this.element,
      setupOptions: (options) => {
        // background must be set to black for proper blending with transparent canvas
        options.setAsString("render.background.color", "#555555");

        // make it look nice
        options.toggle("render.effect.antialiasing.enable");
        options.toggle("render.effect.tone_mapping");
        options.toggle("render.effect.ambient_occlusion");
        options.toggle("render.hdri.ambient");

        // display widgets
        options.toggle("ui.axis", true);
        options.toggle("render.grid.enable", true);

        // default to +Z
        options.setAsString("scene.up_direction", "+Z");
      }
    };
    f3d(settings).then(async (F3D) => {
      F3D.Engine.autoloadPlugins();
      F3D.engineInstance = F3D.Engine.create();
      F3D.setupOptions(F3D.engineInstance.getOptions());
      const canvas = this.element;
      const scale = window.devicePixelRatio;
      F3D.engineInstance
        .getWindow()
        .setSize(scale * canvas.clientWidth, scale * canvas.clientHeight);

      const scene = F3D.engineInstance.getScene();
      scene.clear();
      try {
        scene.addBuffer(data)
      } catch (e) {
        console.log('Unsupported file')
      }
      F3D.engineInstance.getWindow().getCamera().resetToBounds(0.9);
      F3D.engineInstance.getWindow().render();
      F3D.engineInstance.getInteractor().start();
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
