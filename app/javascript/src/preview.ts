

// const Manyfold = {
//   canvas: null as HTMLCanvasElement | null,
//   renderer: null as THREE.WebGLRenderer | null,
//   previews: [] as ObjectPreview[],
//   frame: null as number | null
// }

// const stopAnimation = (): void => {
//   if (Manyfold.frame !== null) {
//     window.cancelAnimationFrame(Manyfold.frame)
//   }
// }

// const onAnimationFrame = (): void => {
//   renderAll()
//   Manyfold.frame = window.requestAnimationFrame(onAnimationFrame)
// }

// const renderAll = (): void => {
//   if (Manyfold.renderer === null) {
//     return
//   }
//   // Move canvas
//   const transform = `translateY(${window.scrollY}px)`
//   Manyfold.renderer.domElement.style.transform = transform
//   // Render all the models
//   Manyfold.previews.forEach((preview) => preview.render())
// }

// const resizeRenderer = (): void => {
//   if (Manyfold.canvas === null || Manyfold.renderer === null) {
//     return
//   }
//   const width = Manyfold.canvas.clientWidth
//   const height = Manyfold.canvas.clientHeight
//   const needResize = Manyfold.canvas.width !== width || Manyfold.canvas.height !== height
//   if (needResize) {
//     Manyfold.renderer.setSize(width, height, false)
//   }
//   renderAll()
// }
// window.addEventListener('resize', resizeRenderer)

// document.addEventListener('DOMContentLoaded', () => {
  // Set up global WebGL context and associated THREE.js renderer
  // Manyfold.canvas = document.getElementById('webgl') as HTMLCanvasElement
  // if (Manyfold.canvas === null) {
  //   console.log(window.i18n.t('renderer.errors.canvas'))
  //   return
  // }
  // Manyfold.renderer = new THREE.WebGLRenderer({ canvas: Manyfold.canvas })
  // if (Manyfold.renderer === null) {
  //   console.log(window.i18n.t('renderer.errors.webglrenderer'))
  //   return
  // }
  // resizeRenderer()
  // Configure previews for each object
  // document.querySelectorAll('[data-preview]').forEach((div) => {
    // Manyfold.previews.push(new ObjectPreview(
    //   div as HTMLDivElement,
    //   (div as HTMLDivElement).dataset,
    //   div.getElementsByClassName('progress')[0] as HTMLDivElement
    // ))
  // })
  // Start animation
  // onAnimationFrame()
// })

// document.addEventListener('visibilitychange', () => {
//   if (document.visibilityState === 'visible') {
//     onAnimationFrame()
//   } else {
//     stopAnimation()
//   }
// })

// export { ObjectPreview }

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
        ... canvas.dataset
      }
    }, [offscreen]);
  });
});
