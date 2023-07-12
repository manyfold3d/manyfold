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
    this.progressIndicator.onclick = function () {
      this.load()
    }.bind(this)
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

const VanDAM = {
  canvas: null as HTMLCanvasElement | null,
  renderer: null as THREE.WebGLRenderer | null,
  previews: [] as ObjectPreview[],
  frame: null as number | null
}

const stopAnimation = (): void => {
  if (VanDAM.frame !== null) {
    window.cancelAnimationFrame(VanDAM.frame)
  }
}

const onAnimationFrame = (): void => {
  VanDAM.previews.forEach((preview) => {
    if (preview.ready) {
      preview.controls.update()
      VanDAM.renderer?.render(preview.scene, preview.camera)
    }
  })
  VanDAM.frame = window.requestAnimationFrame(onAnimationFrame)
}

document.addEventListener('DOMContentLoaded', () => {
  // Set up global WebGL context and associated THREE.js renderer
  VanDAM.canvas = document.getElementById('webgl') as HTMLCanvasElement
  if (VanDAM.canvas === null) {
    console.log('Could not find #webgl canvas!')
    return
  }
  VanDAM.renderer = new THREE.WebGLRenderer({ canvas: VanDAM.canvas })
  if (VanDAM.renderer === null) {
    console.log('Could not create renderer!')
    return
  }
  // Configure previews for each object
  document.querySelectorAll('[data-preview]').forEach((div) => {
    VanDAM.previews.push(new ObjectPreview(
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
