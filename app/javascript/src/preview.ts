import * as THREE from 'three'
import { OBJLoader } from 'three/examples/jsm/loaders/OBJLoader.js'
import { STLLoader } from 'three/examples/jsm/loaders/STLLoader.js'
import { ThreeMFLoader } from 'three/examples/jsm/loaders/3MFLoader.js'
import { PLYLoader } from 'three/examples/jsm/loaders/PLYLoader.js'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'

class ObjectPreview {
  constructor (canvas, progressIndicator, url, format, yUp, gridSizeX, gridSizeZ) {
    this.canvas = canvas
    this.progressIndicator = progressIndicator
    this.url = url
    this.format = format
    this.yUp = yUp
    this.gridSizeX = gridSizeX
    this.gridSizeZ = gridSizeZ
    const observer = new window.IntersectionObserver(this.onIntersectionChanged.bind(this), {})
    observer.observe(canvas)
  }

  setup (): void {
    this.scene = new THREE.Scene()
    this.renderer = new THREE.WebGLRenderer({ canvas: this.canvas })
    this.camera = new THREE.PerspectiveCamera(45, this.canvas.width / this.canvas.height, 0.1, 1000)
    this.camera.position.z = 50
    this.controls = new OrbitControls(this.camera, this.renderer.domElement)
    this.controls.enableDamping = true
    this.controls.enablePan = false
    this.controls.enableZoom = false
  }

  onIntersectionChanged (entries, observer): void {
    this.cleanup()
    if (entries[0].isIntersecting === true) {
      this.load(this.url, this.format)
    }
  }

  load (url, format): void {
    let loader = null
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
      loader.load(url,
        this.onLoad.bind(this),
        this.onProgress.bind(this),
        this.onLoadError.bind(this)
      )
    }
  }

  onProgress (xhr): void {
    const percentage = Math.floor(xhr.loaded / xhr.total * 100).toString() + '%'
    this.progressIndicator.style.width = percentage
    this.progressIndicator.ariaValueNow = percentage
    this.progressIndicator.textContent = percentage
  }

  onLoad (model): void {
    this.setup()
    const material = new THREE.MeshNormalMaterial({
      flatShading: true
    })
    let object = null
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
    // Transform to screen coords from print
    if (this.yUp === false) {
      const coordSystemTransform = new THREE.Matrix4()
      coordSystemTransform.set(
        1, 0, 0, 0, // x -> x
        0, 0, 1, 0, // z -> y
        0, -1, 0, 0, // y -> -z
        0, 0, 0, 1)
      object.applyMatrix4(coordSystemTransform)
    }
    // Calculate bounding volumes
    const bbox = new THREE.Box3().setFromObject(object)
    const centre = new THREE.Vector3()
    bbox.getCenter(centre)
    const bsphere = new THREE.Sphere()
    bbox.getBoundingSphere(bsphere)
    const modelheight = bbox.max.y - bbox.min.y
    // Configure camera
    this.camera.position.z = this.camera.position.x = bsphere.radius * 1.63
    this.camera.position.y = bsphere.radius * 0.75

    this.controls.target = new THREE.Vector3(0, modelheight / 2, 0)
    // Centre the model
    object.position.set(-centre.x, -bbox.min.y, -centre.z)
    this.scene.add(object)
    // Add the grid
    this.gridHelper = new THREE.GridHelper(this.gridSizeX, this.gridSizeX / 10, 'magenta', 'cyan')
    this.scene.add(this.gridHelper)
    // Render first frame
    this.onAnimationFrame()

    bbox.dispose()
    centre.dispose()
    bsphere.dispose()
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

document.addEventListener('turbolinks:load', () => {
  document.querySelectorAll('[data-preview]').forEach((div) => {
    const canvas = div.getElementsByTagName('canvas')[0]
    canvas.height = canvas.width
    canvas.renderer = new ObjectPreview(
      canvas,
      div.getElementsByClassName('progress-bar')[0],
      canvas.dataset.previewUrl,
      canvas.dataset.format,
      (canvas.dataset.yUp === 'true'),
      canvas.dataset.gridSizeX,
      canvas.dataset.gridSizeZ
    )
  })
})
