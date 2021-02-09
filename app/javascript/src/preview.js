import * as THREE from 'three';
import { OBJLoader } from 'three/examples/jsm/loaders/OBJLoader.js';
import { STLLoader } from 'three/examples/jsm/loaders/STLLoader.js';

export function preview(canvas) {

  var scene = new THREE.Scene();
  var camera = new THREE.PerspectiveCamera(45, canvas.width / canvas.height, 0.1, 1000);
  camera.position.z = 50;

  var renderer = new THREE.WebGLRenderer({canvas, alpha: true});

  const objects = new THREE.Group();
  scene.add(objects);

  const light = new THREE.AmbientLight(0x404040); // soft white light
  scene.add(light);

  const directionalLight = new THREE.DirectionalLight({position: new THREE.Vector3( 0, 1, 1 )});
  scene.add(directionalLight);

  const material = new THREE.MeshLambertMaterial({
    color: 0x00ff00
  });

  var loader = null;
  if (canvas.dataset.format === "obj")
    loader = new OBJLoader();
  else if (canvas.dataset.format === "stl")
    loader = new STLLoader();


  loader.load( canvas.dataset.previewUrl, function ( model ) {
    var geometry = null;
    if (canvas.dataset.format === "obj")
      geometry = model.geometry;
    else if (canvas.dataset.format === "stl")
      geometry = model;
    objects.add( new THREE.Mesh(geometry, material) );
  }, undefined, function ( error ) {
    console.error( error );
  } );

  var animate = function() {
    requestAnimationFrame(animate);

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
