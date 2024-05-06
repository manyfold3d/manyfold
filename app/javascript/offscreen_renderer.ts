import * as THREE from 'three'
import { OBJLoader } from 'three/examples/jsm/loaders/OBJLoader.js'
import { STLLoader } from 'three/examples/jsm/loaders/STLLoader.js'
import { ThreeMFLoader } from 'three/examples/jsm/loaders/3MFLoader.js'
import { PLYLoader } from 'three/examples/jsm/loaders/PLYLoader.js'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'

// Web worker message handlers
const handlers = {
  initialize,
  resize,
};

var preview = null;

// Web worker message router
self.onmessage = function (message) {
  const fn = handlers[message.data.type];
  if (typeof fn !== 'function') {
    throw new Error('no handler for type: ' + message.data.type);
  }
  fn(message.data.payload);
};

function initialize (data) {
  const {canvas, ...settings} = data
  preview = new ObjectPreview(canvas, settings)
}

function resize (data) {
  preview.resize()
}

class ObjectPreview {
  canvas: HTMLCanvasElement
  renderer: THREE.WebGLRenderer
  settings: DOMStringMap
  scene: THREE.Scene
  camera: THREE.PerspectiveCamera
  controls: OrbitControls
  gridHelper: THREE.GridHelper
  ready: boolean
  canvasWidth: number
  canvasHeight: number

  constructor (
    canvas: HTMLCanvasElement,
    settings: DOMStringMap,
  ) {
    this.ready = false
    this.canvas = canvas
    this.canvasWidth = 256
    this.canvasHeight = 256
    this.renderer = new THREE.WebGLRenderer({ canvas: this.canvas })
    this.settings = settings
    if (this.settings.autoLoad === 'true') {
      this.load();
    }
  }

  setup (): void {
  	this.scene = new THREE.Scene()
    this.scene.background = new THREE.Color(this.settings.backgroundColour ?? '#000000')
  	this.camera = new THREE.PerspectiveCamera(
  		45,
      this.canvasWidth / this.canvasHeight,
  		0.1,
  		1000
  	)
    //resize();
  	// this.controls = new OrbitControls(this.camera, this.canvas)
  	// this.controls.enableDamping = true
    // this.controls.enablePan = this.controls.enableZoom = (this.settings.enablePanZoom === 'true')
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
      // case '3mf':
      //   loader = new ThreeMFLoader()
      //   break
      case 'ply':
        loader = new PLYLoader()
        break
    }
    if (loader !== null) {
      console.log("Loading " + this.settings.previewUrl)
      loader.load(
        this.settings.previewUrl ?? '',
        this.onLoad.bind(this),
        this.onLoadProgress.bind(this),
        this.onLoadError.bind(this)
      )
    }
  }

  onLoadProgress (xhr): void {
    const percentage = Math.floor((xhr.loaded / xhr.total) * 100)
    postMessage({
      "type": "onLoadProgress",
      "payload": {
        "percentage": percentage
      }
    })

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
    if (model.type === 'BufferGeometry' || model.type === 'BoxGeometry') {
      object = new THREE.Mesh(model, material)
    } else {
      model.traverse(function (node) {
        if (node instanceof THREE.Mesh) {
          node.material = material
        }
      })
      object = model
    }

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
    // Centre the model
    object.position.set(-centre.x, -bbox.min.y, -centre.z)

    // Configure camera
    this.camera.position.z = this.camera.position.x = -bsphere.radius * 1.63
    this.camera.position.y = bsphere.radius * 0.75
    const target = new THREE.Vector3(0, modelHeight / 2, 0)
    this.camera.lookAt(target)
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

    // Let's go!
    this.ready = true
    this.render()

    // Report load complete
    postMessage({ "type": "onLoad" })
  }

  onLoadError (e): void {
    console.log(e)
    postMessage({ "type": "onLoadError" })
    this.onLoad(new THREE.BoxGeometry(2,3,4))
  }

  resize (): void {
    this.camera.aspect = this.canvasWidth / this.canvasHeight
    this.camera.updateProjectionMatrix()
    // next, set the renderer to the same size as our container element
    this.renderer.setSize(this.canvasWidth, this.canvasHeight);
    // finally, set the pixel ratio so that our scene will look good on HiDPI displays
    // this.renderer.setPixelRatio(window.devicePixelRatio);
  }

  render (): void {
    if (!this.ready || this.canvas === null || this.renderer === null) {
      return
    }
    // Render
    console.log("rendering")
    this.renderer.clear()
    this.renderer.render(this.scene, this.camera)
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
