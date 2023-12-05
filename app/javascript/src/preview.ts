import * as THREE from 'three'
import { OBJLoader } from 'three/examples/jsm/loaders/OBJLoader.js'
import { STLLoader } from 'three/examples/jsm/loaders/STLLoader.js'
import { ThreeMFLoader } from 'three/examples/jsm/loaders/3MFLoader.js'
import { PLYLoader } from 'three/examples/jsm/loaders/PLYLoader.js'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'

class ObjectPreview {
  container: HTMLDivElement
  progressIndicator: HTMLDivElement
  progressBar: HTMLDivElement
  progressLabel: HTMLSpanElement
  settings: DOMStringMap
  scene: THREE.Scene
  camera: THREE.PerspectiveCamera
  controls: OrbitControls
  gridHelper: THREE.GridHelper
  ready: boolean

  constructor (
    container: HTMLDivElement,
    settings: DOMStringMap,
    progressIndicator: HTMLDivElement
  ) {
    this.ready = false
    this.container = container
    this.settings = settings
    this.progressIndicator = progressIndicator
    this.progressBar = progressIndicator.getElementsByClassName('progress-bar')[0] as HTMLDivElement
    this.progressLabel = progressIndicator.getElementsByClassName('progress-label')[0] as HTMLSpanElement
    if (this.settings.autoLoad === 'true') {
      this.load()
    } else {
      this.progressIndicator.onclick = function () {
        this.load()
      }.bind(this)
    }
  }

  setup (): void {
    this.scene = new THREE.Scene()
    this.scene.background = new THREE.Color(this.settings.backgroundColour ?? '#000000')
    this.camera = new THREE.PerspectiveCamera(
      45,
      this.container.clientWidth / this.container.clientHeight,
      0.1,
      1000
    )
    this.camera.position.z = 50
    this.controls = new OrbitControls(this.camera, this.container)
    this.controls.enableDamping = true
    this.controls.enablePan = this.controls.enableZoom = (this.settings.enablePanZoom === 'true')
    // Add lighting
    const gridSizeX = parseInt(this.settings.gridSizeX ?? '10', 10)
    const gridSizeZ = parseInt(this.settings.gridSizeZ ?? '10', 10)
    this.scene.add(new THREE.HemisphereLight(0xffffff, 0x404040))
    const light = new THREE.PointLight(0xffffff, 0.25)
    light.position.set(gridSizeX, 50, gridSizeZ)
    this.scene.add(light)
    const light2 = new THREE.PointLight(0xffffff, 0.25)
    light2.position.set(-gridSizeX, 50, gridSizeZ)
    this.scene.add(light2)
  }

  load (): void {
    let loader: OBJLoader | STLLoader | ThreeMFLoader | PLYLoader | null = null
    switch (this.settings.format) {
      case 'obj':
        loader = new OBJLoader()
        break
      case 'stl':
        loader = new STLLoader()
        break
      case '3mf':
        loader = new ThreeMFLoader()
        break
      case 'ply':
        loader = new PLYLoader()
        break
    }
    if (loader !== null) {
      loader.load(
        this.settings.previewUrl ?? '',
        this.onLoad.bind(this),
        this.onProgress.bind(this),
        this.onLoadError.bind(this)
      )
    }
  }

  onProgress (xhr): void {
    const percentage =
      Math.floor((xhr.loaded / xhr.total) * 100).toString() + '%'
    this.progressBar.style.width = this.progressBar.ariaValueNow =
      this.progressLabel.textContent = percentage
  }

  onLoad (model): void {
    this.setup()
    const material = this.settings.renderStyle === 'normals'
      ? new THREE.MeshNormalMaterial({
        flatShading: true
      })
      : new THREE.MeshLambertMaterial({
        flatShading: true,
        color: (this.settings.objectColour ?? '#cccccc')
      })
    // find mesh and set material
    let object: THREE.Mesh | null = null
    if (model.type === 'BufferGeometry') {
      object = new THREE.Mesh(model, material)
    } else {
      model.traverse(function (node) {
        if (node instanceof THREE.Mesh) {
          node.material = material
        }
      })
      object = model
    }
    if (object == null) return

    // Transform to screen coords from print
    if (this.settings.yUp !== 'true') {
      const coordSystemTransform = new THREE.Matrix4()
      coordSystemTransform.set(
        1,
        0,
        0,
        0, // x -> x
        0,
        0,
        1,
        0, // z -> y
        0,
        -1,
        0,
        0, // y -> -z
        0,
        0,
        0,
        1
      )
      object.applyMatrix4(coordSystemTransform)
    }
    // Calculate bounding volumes
    const bbox = new THREE.Box3().setFromObject(object)
    const centre = new THREE.Vector3()
    bbox.getCenter(centre)
    const bsphere = new THREE.Sphere()
    bbox.getBoundingSphere(bsphere)
    const modelHeight = bbox.max.y - bbox.min.y
    // Configure camera
    this.camera.position.z = this.camera.position.x = bsphere.radius * 1.63
    this.camera.position.y = bsphere.radius * 0.75

    this.controls.target = new THREE.Vector3(0, modelHeight / 2, 0)
    // Centre the model
    object.position.set(-centre.x, -bbox.min.y, -centre.z)
    this.scene.add(object)
    // Add the grid
    if (this.settings.showGrid === 'true') {
      const gridSizeX = parseInt(this.settings.gridSizeX ?? '10', 10)
      // TODO: use grid size Z here, see #834
      this.gridHelper = new THREE.GridHelper(
        gridSizeX,
        gridSizeX / 10,
        'magenta',
        'cyan'
      )
      this.scene.add(this.gridHelper)
    }
    // Hide the progress bar
    this.progressIndicator.style.display = 'none'
    // Let's go!
    this.ready = true
  }

  onLoadError (): void {
    this.progressBar.classList.add('bg-danger')
    this.progressBar.style.width = this.progressBar.ariaValueNow = '100%'
    this.progressLabel.textContent = 'Load Error'
  }

  render (): void {
    if (!this.ready || Manyfold.canvas === null || Manyfold.renderer === null) {
      return
    }
    this.controls.update()
    // Set scissor regions
    const { left, right, top, bottom, width, height } =
      this.container.getBoundingClientRect()
    const isOffscreen =
      bottom < 0 ||
      top > (Manyfold.canvas.clientHeight ?? 0) ||
      right < 0 ||
      left > (Manyfold.canvas.clientWidth ?? 0)
    if (!isOffscreen) {
      this.camera.aspect = this.container.clientWidth / this.container.clientHeight
      this.camera.updateProjectionMatrix()
      const positiveYUpBottom = (Manyfold.canvas.height ?? 0) - bottom
      Manyfold.renderer.setScissorTest(true)
      Manyfold.renderer.setScissor(left, positiveYUpBottom, width, height)
      Manyfold.renderer.setViewport(left, positiveYUpBottom, width, height)
      // Render
      Manyfold.renderer.clear()
      Manyfold.renderer.render(this.scene, this.camera)
    }
  }

  cleanup (): void {
    if (typeof this.scene !== 'undefined' && this.scene !== null) {
      this.scene.traverse(function (node) {
        if (node instanceof THREE.Mesh) {
          node.geometry.dispose()
          node.material.dispose()
        }
      })
    }
  }
}

const Manyfold = {
  canvas: null as HTMLCanvasElement | null,
  renderer: null as THREE.WebGLRenderer | null,
  previews: [] as ObjectPreview[],
  frame: null as number | null
}

const stopAnimation = (): void => {
  if (Manyfold.frame !== null) {
    window.cancelAnimationFrame(Manyfold.frame)
  }
}

const onAnimationFrame = (): void => {
  renderAll()
  Manyfold.frame = window.requestAnimationFrame(onAnimationFrame)
}

const renderAll = (): void => {
  if (Manyfold.renderer === null) {
    return
  }
  // Move canvas
  const transform = `translateY(${window.scrollY}px)`
  Manyfold.renderer.domElement.style.transform = transform
  // Render all the models
  Manyfold.previews.forEach((preview) => preview.render())
}

const resizeRenderer = (): void => {
  if (Manyfold.canvas === null || Manyfold.renderer === null) {
    return
  }
  const width = Manyfold.canvas.clientWidth
  const height = Manyfold.canvas.clientHeight
  const needResize = Manyfold.canvas.width !== width || Manyfold.canvas.height !== height
  if (needResize) {
    Manyfold.renderer.setSize(width, height, false)
  }
  renderAll()
}
window.addEventListener('resize', resizeRenderer)

document.addEventListener('DOMContentLoaded', () => {
  // Set up global WebGL context and associated THREE.js renderer
  Manyfold.canvas = document.getElementById('webgl') as HTMLCanvasElement
  if (Manyfold.canvas === null) {
    console.log('Could not find #webgl canvas!')
    return
  }
  Manyfold.renderer = new THREE.WebGLRenderer({ canvas: Manyfold.canvas })
  if (Manyfold.renderer === null) {
    console.log('Could not create renderer!')
    return
  }
  resizeRenderer()
  // Configure previews for each object
  document.querySelectorAll('[data-preview]').forEach((div) => {
    Manyfold.previews.push(new ObjectPreview(
      div as HTMLDivElement,
      (div as HTMLDivElement).dataset,
      div.getElementsByClassName('progress')[0] as HTMLDivElement
    ))
  })
  // Start animation
  onAnimationFrame()
})

document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'visible') {
    onAnimationFrame()
  } else {
    stopAnimation()
  }
})

export { ObjectPreview }
