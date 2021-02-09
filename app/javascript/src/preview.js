import * as THREE from 'three'
import { OBJLoader } from 'three/examples/jsm/loaders/OBJLoader.js'
import { STLLoader } from 'three/examples/jsm/loaders/STLLoader.js'

export function preview (canvas) {
  const scene = new THREE.Scene()
  const camera = new THREE.PerspectiveCamera(45, canvas.width / canvas.height, 0.1, 1000)
  camera.position.z = 50

  const renderer = new THREE.WebGLRenderer({ canvas })

  const objects = new THREE.Group()
  scene.add(objects)

  const material = new THREE.MeshNormalMaterial({
    flatShading: true
  })

  let loader = null
  if (canvas.dataset.format === 'obj') { loader = new OBJLoader() } else if (canvas.dataset.format === 'stl') { loader = new STLLoader() }

  const gridHelper = new THREE.GridHelper(260,26,"magenta","cyan");
  objects.add(gridHelper)

  let geometry = null;
  loader.load(canvas.dataset.previewUrl, function (model) {
    if (canvas.dataset.format === 'obj') { geometry = model.geometry } else if (canvas.dataset.format === 'stl') { geometry = model }
    // Create mesh and transform to screen coords from print
    const coord_system_transform = new THREE.Matrix4();
    coord_system_transform.set(
      1, 0, 0, 0, // x -> x
      0, 0, 1, 0, // z -> y
      0, -1, 0, 0, // y -> -z
      0, 0, 0, 1);
    const mesh = new THREE.Mesh(geometry.applyMatrix4(coord_system_transform), material)
    // Calculate bounding volumes
    const bbox = new THREE.Box3().setFromObject(mesh)
    const centre = new THREE.Vector3()
    bbox.getCenter(centre)
    const bsphere = new THREE.Sphere()
    bbox.getBoundingSphere(bsphere)
    const modelheight = bbox.max.y - bbox.min.y
    // Configure camera
    camera.position.z = bsphere.radius * 2.3
    camera.position.y = bsphere.radius * 0.75
    camera.lookAt(0,modelheight/2,0)
    // Centre the model
    mesh.position.set(-centre.x, -bbox.min.y, -centre.z)
    objects.add(mesh)
  }, undefined, function (error) {
    console.error(error)
  })

  const animate = function () {
    if (canvas.closest('html')) { // There's probably more efficient way to do this than checking every frame, but I can't make MutationObserver work right now
      objects.rotation.y += 0.01
      renderer.render(scene, camera)
      window.requestAnimationFrame(animate)
    }
    else {
      gridHelper.geometry.dispose()
      material.dispose()
      geometry.dispose()
      renderer.dispose()
    }
  }

  animate()
}

document.addEventListener('turbolinks:load', () => {
  document.querySelectorAll('canvas[data-preview]').forEach((canvas) => {
    canvas.height = canvas.width;
    preview(canvas)
  })
})
