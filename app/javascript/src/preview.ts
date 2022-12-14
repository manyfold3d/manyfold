import * as THREE from 'three'
import { OBJLoader } from 'three/examples/jsm/loaders/OBJLoader.js'
import { STLLoader } from 'three/examples/jsm/loaders/STLLoader.js'
import { ThreeMFLoader } from 'three/examples/jsm/loaders/3MFLoader.js'
import { PLYLoader } from 'three/examples/jsm/loaders/PLYLoader.js'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'

class ObjectPreview {
  canvas: HTMLCanvasElement
  url: string
  format: string
  yUp: boolean
  gridSizeX: number
  gridSizeZ: number
  backgroundColour: string
  objectColour: string
  renderStyle: string
  enablePanZoom: boolean
  showGrid: boolean
  scene: THREE.Scene
  renderer: THREE.WebGLRenderer
  camera: THREE.PerspectiveCamera
  controls: OrbitControls
  gridHelper: THREE.GridHelper
  frame: number
  progressIndicator: HTMLDivElement
  constructor (
    canvas: HTMLCanvasElement,
    progressIndicator: HTMLDivElement
  ) {
    this.canvas = canvas
    this.progressIndicator = progressIndicator
    this.url = canvas.dataset.previewUrl
    this.format = canvas.dataset.format
    this.yUp = canvas.dataset.yUp === 'true'
    this.gridSizeX = parseInt(canvas.dataset.gridSizeX ?? '10', 10)
    this.gridSizeZ = parseInt(canvas.dataset.gridSizeZ ?? '10', 10)
    this.backgroundColour = canvas.dataset.backgroundColour
    this.objectColour = canvas.dataset.objectColour
    this.renderStyle = canvas.dataset.renderStyle
    this.enablePanZoom = canvas.dataset.enablePanZoom === 'true'
    this.showGrid = canvas.dataset.showGrid === 'true'
    const observer = new window.IntersectionObserver(
      this.onIntersectionChanged.bind(this),
      {}
    )
    observer.observe(canvas)
  }

  setup (): void {
    this.scene = new THREE.Scene()
    this.scene.background = new THREE.Color(this.backgroundColour)
    this.renderer = new THREE.WebGLRenderer({ canvas: this.canvas })
    this.camera = new THREE.PerspectiveCamera(
      45,
      this.canvas.clientWidth / this.canvas.clientHeight,
      0.1,
      1000
    )
    this.camera.position.z = 50
    this.renderer.setSize(
      this.canvas.clientWidth,
      this.canvas.clientHeight,
      false
    )
    this.controls = new OrbitControls(this.camera, this.renderer.domElement)
    this.controls.enableDamping = true
    this.controls.enablePan = this.enablePanZoom
    this.controls.enableZoom = this.enablePanZoom
    // Add lighting
    this.hemiLight = new THREE.HemisphereLight(0xffffff, 0x404040)
    this.scene.add(this.hemiLight)
    const light = new THREE.PointLight(0xffffff, 0.25)
    light.position.set(250, 50, 100)
    this.scene.add(light)
    const light2 = new THREE.PointLight(0xffffff, 0.25)
    light2.position.set(-250, 50, 100)
    this.scene.add(light2)
  }

  onIntersectionChanged (entries, observer): void {
    this.cleanup()
    if (entries[0].isIntersecting === true) {
      this.load(this.url, this.format)
    }
  }

  load (url: string, format: string): void {
    let loader: OBJLoader | STLLoader | ThreeMFLoader | PLYLoader | null = null
    switch (format) {
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
        url,
        this.onLoad.bind(this),
        this.onProgress.bind(this),
        this.onLoadError.bind(this)
      )
    }
  }

  onProgress (xhr): void {
    const percentage =
      Math.floor((xhr.loaded / xhr.total) * 100).toString() + '%'
    this.progressIndicator.style.width = percentage
    this.progressIndicator.ariaValueNow = percentage
    this.progressIndicator.textContent = percentage
  }

  onLoad (model): void {
    this.setup()
    const material = this.renderStyle === 'normals'
      ? new THREE.MeshNormalMaterial({
        flatShading: true
      })
      : new THREE.MeshLambertMaterial({
        flatShading: false,
        color: this.objectColour
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
    if (!this.yUp) {
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
    if (this.showGrid) {
      // TODO: use grid size Z here, see #834
      this.gridHelper = new THREE.GridHelper(
        this.gridSizeX,
        this.gridSizeX / 10,
        'magenta',
        'cyan'
      )
      this.scene.add(this.gridHelper)
    }
    // Render first frame
    this.onAnimationFrame()
  }

  onLoadError (): void {
    this.progressIndicator.classList.add('bg-danger')
    this.progressIndicator.style.width = '100%'
    this.progressIndicator.ariaValueNow = '100%'
    this.progressIndicator.textContent = 'Load Error'
  }

  stopAnimation (): void {
    window.cancelAnimationFrame(this.frame)
  }

  onAnimationFrame (): void {
    this.controls.update()
    this.renderer.render(this.scene, this.camera)
    this.frame = window.requestAnimationFrame(this.onAnimationFrame.bind(this))
  }

  cleanup (): void {
    this.stopAnimation()
    if (typeof this.scene !== 'undefined' && this.scene !== null) {
      this.scene.traverse(function (node) {
        if (node instanceof THREE.Mesh) {
          node.geometry.dispose()
          node.material.dispose()
        }
      })
    }
    if (typeof this.renderer !== 'undefined' && this.renderer !== null) {
      this.renderer.dispose()
    }
  }
}

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('[data-preview]').forEach((div) => {
    const canvas = div.getElementsByTagName('canvas')[0]
    canvas.height = canvas.width
    canvas.renderer = new ObjectPreview(
      canvas,
      div.getElementsByClassName('progress-bar')[0] as HTMLDivElement
    )
  })
})

export { ObjectPreview }
