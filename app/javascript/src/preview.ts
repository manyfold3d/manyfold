import * as Comlink from 'comlink';
import 'src/comlink_event_handler'

var progressBar = null;
var progressLabel = null;

const load = async (preview) => {
  await preview.load(
    Comlink.proxy(onLoad),
    Comlink.proxy(onLoadProgress),
    Comlink.proxy(onLoadError)
  );
}

const onLoadProgress = (percentage) => {
  if (percentage == 100) {
    progressLabel.textContent = "Reticulating splines..."
  }
  else {
    progressLabel.textContent = percentage + '%'
  }
  progressBar.style.width = percentage + '%'
  progressBar.ariaValueNow = percentage
}

const onLoad = () => {
  progressBar.parentElement.remove()
  progressBar = null;
  progressLabel = null;
}

const onLoadError = () => {
  progressBar.classList.add('bg-danger')
  progressBar.style.width = progressBar.ariaValueNow = '100%'
  progressLabel.textContent = window.i18n.t('renderer.errors.load')
}

const handlers = {
  onLoadProgress,
  onLoad,
  onLoadError
}

const onWorkerMessage = (message) => {
  const fn = handlers[message.data.type];
  if (typeof fn !== 'function') {
    throw new Error('no handler for type: ' + message.data.type);
  }
  fn(message.data.payload);
}

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('[data-preview]').forEach(async (canvas) => {
    progressBar = canvas.parentElement?.getElementsByClassName("progress-bar")[0];
    progressLabel = canvas.parentElement?.getElementsByClassName("progress-label")[0];
    // Create offscreen renderer worker
    const ObjectPreview = Comlink.wrap(
      new Worker("/assets/offscreen_renderer.js", { type: 'module' })
    );
    const offscreenCanvas = canvas.transferControlToOffscreen();
    const preview = await new ObjectPreview(
      Comlink.transfer(offscreenCanvas, [offscreenCanvas]),
      {
        ...canvas.dataset
      },
      {
        width: canvas.clientWidth,
        height: canvas.clientHeight,
        pixelRatio: window.devicePixelRatio
      }
    );
    // Send resize events
    window.addEventListener('resize', () => (preview.resize(canvas.clientWidth, canvas.clientHeight)))
    // Handle interaction events
    const eventHandlers = [
      "mousedown",
      "mousemove",
      "mouseup",
      "pointerdown",
      "pointermove",
      "pointerup",
      "touchstart",
      "touchmove",
      "touchend",
      "wheel",
      "keydown",
      "keyup"
    ];
    eventHandlers.forEach((eventName) => {
      canvas.addEventListener(eventName, preview.handleEvent.bind(preview))
    });
    // Autoload
    if (canvas.dataset.autoLoad === 'true') {
      load(preview)
    }
  });
});
