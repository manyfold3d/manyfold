import * as THREE from 'three';
import { OBJLoader } from 'three/examples/jsm/loaders/OBJLoader.js';

export function preview(canvas) {

  var scene = new THREE.Scene();
  var camera = new THREE.PerspectiveCamera(75, canvas.width / canvas.height, 0.1, 1000);

  var renderer = new THREE.WebGLRenderer({canvas, alpha: true});


  const loader = new OBJLoader();
  const objects = new THREE.Group();
  scene.add(objects);
  loader.load( canvas.dataset.previewUrl, function ( object ) {
    objects.add( object );
  }, undefined, function ( error ) {
    console.error( error );
  } );

  camera.position.z = 50;

  const light = new THREE.AmbientLight(0x404040); // soft white light
  scene.add(light);

  const directionalLight = new THREE.DirectionalLight({position: new THREE.Vector3( 0, 1, 1 )});
  scene.add(directionalLight);

  var animate = function() {
    requestAnimationFrame(animate);

    objects.rotation.x += 0.01;
    objects.rotation.y += 0.01;

    renderer.render(scene, camera);
  };

  animate();
}

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('canvas[data-preview]').forEach((canvas) => {
    preview(canvas)
  })
})
