var progressBar = null;
var progressLabel = null;

const onLoadProgress = (data) => {
  if (data.percentage == 100) {
    progressLabel.textContent = "Reticulating splines..."
  }
  else {
    progressLabel.textContent = data.percentage + '%'
  }
  progressBar.style.width = data.percentage + '%'
  progressBar.ariaValueNow = data.percentage
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
  document.querySelectorAll('[data-preview]').forEach((canvas) => {
    progressBar = canvas.parentElement?.getElementsByClassName("progress-bar")[0];
    progressLabel = canvas.parentElement?.getElementsByClassName("progress-label")[0];
    const worker = new Worker("/assets/offscreen_renderer.js", { type: 'module' });
    console.log(canvas);
    const offscreen = canvas.transferControlToOffscreen();
    worker.onmessage = onWorkerMessage
    worker.postMessage({
      type: 'initialize',
      payload: {
        canvas: offscreen,
        settings: {
          ...canvas.dataset
        },
        state: {
          width: canvas.clientWidth,
          height: canvas.clientHeight,
          pixelRatio: window.devicePixelRatio
        }
      }
    }, [offscreen]);
    // Handle resizing
    window.addEventListener('resize', () => {
      worker.postMessage({
        type: 'resize',
        payload: {
          width: canvas.clientWidth,
          height: canvas.clientHeight
        }
      });
    })
  });
});
