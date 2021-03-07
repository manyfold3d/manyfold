import * as THREE from 'three'
import { OBJLoader } from 'three/examples/jsm/loaders/OBJLoader.js'
import { STLLoader } from 'three/examples/jsm/loaders/STLLoader.js'

class PartPreview {
  constructor (canvas, url, format) {
    this.canvas = canvas
    this.url = url
    this.format = format
    // Trigger loading when canvas becomes visible
    this.loading = false
    const observer = new window.IntersectionObserver(this.onIntersectionChanged.bind(this), {})
    observer.observe(canvas)
    this.setup()
  }

  setup () {
    this.scene = new THREE.Scene()
    this.renderer = new THREE.WebGLRenderer({ canvas: this.canvas })
    this.camera = new THREE.PerspectiveCamera(45, this.canvas.width / this.canvas.height, 0.1, 1000)
    this.camera.position.z = 50
    // Start animation loop
    this.animate()
  }

  onIntersectionChanged (entries, observer) {
    if (entries[0].isIntersecting) {
      this.onBecomeVisible()
    }
  }

  onBecomeVisible () {
    if (this.loading === false) {
      this.loading = true
      this.load(this.url, this.format)
    }
  }

  load (url, format) {
    let loader = null
    if (format === 'obj') { loader = new OBJLoader() } else if (format === 'stl') { loader = new STLLoader() }

    loader.load(url,
      this.onLoad.bind(this),
      undefined,
      this.onLoadError.bind(this)
    )
  }

  onLoad (model) {
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
    const coordSystemTransform = new THREE.Matrix4()
    coordSystemTransform.set(
      1, 0, 0, 0, // x -> x
      0, 0, 1, 0, // z -> y
      0, -1, 0, 0, // y -> -z
      0, 0, 0, 1)
    object.applyMatrix4(coordSystemTransform)
    // Calculate bounding volumes
    const bbox = new THREE.Box3().setFromObject(object)
    const centre = new THREE.Vector3()
    bbox.getCenter(centre)
    const bsphere = new THREE.Sphere()
    bbox.getBoundingSphere(bsphere)
    const modelheight = bbox.max.y - bbox.min.y
    // Configure camera
    this.camera.position.z = bsphere.radius * 2.3
    this.camera.position.y = bsphere.radius * 0.75
    this.camera.lookAt(0, modelheight / 2, 0)
    // Centre the model
    object.position.set(-centre.x, -bbox.min.y, -centre.z)
    this.scene.add(object)
    // Add the grid
    this.gridHelper = new THREE.GridHelper(260, 26, 'magenta', 'cyan')
    this.scene.add(this.gridHelper)
  }

  onLoadError (error) {
    console.error(error)
  }

  animate () {
    if (this.canvas.closest('html')) { // There's probably more efficient way to do this than checking every frame, but I can't make MutationObserver work right now
      this.scene.rotation.y += 0.01
      this.renderer.render(this.scene, this.camera)
      window.requestAnimationFrame(this.animate.bind(this))
    } else {
      this.cleanup()
    }
  }

  cleanup () {
    this.scene.traverse(function (node) {
      if (node instanceof THREE.Mesh) {
        node.geometry.dispose()
        node.material.dispose()
      }
    })
    this.renderer.dispose()
  }
}

document.addEventListener('turbolinks:load', () => {
  document.querySelectorAll('canvas[data-preview]').forEach((canvas) => {
    canvas.height = canvas.width
    canvas.renderer = new PartPreview(
      canvas,
      canvas.dataset.previewUrl,
      canvas.dataset.format
    )
  })
})
