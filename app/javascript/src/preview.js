import * as THREE from 'three';

export function preview(canvas) {

  var scene = new THREE.Scene();
  var camera = new THREE.PerspectiveCamera(75, canvas.width / canvas.height, 0.1, 1000);

  var renderer = new THREE.WebGLRenderer({canvas, alpha: true});

  var geometry = new THREE.BoxGeometry(1, 1, 1);
  var material = new THREE.MeshLambertMaterial({
    color: 0x00ff00
  });
  var cube = new THREE.Mesh(geometry, material);
  scene.add(cube);

  camera.position.z = 5;

  const light = new THREE.AmbientLight(0x404040); // soft white light
  scene.add(light);

  const directionalLight = new THREE.DirectionalLight(0xffffff, 0.5);
  scene.add(directionalLight);

  var animate = function() {
    requestAnimationFrame(animate);

    cube.rotation.x += 0.01;
    cube.rotation.y += 0.01;

    renderer.render(scene, camera);
  };

  animate();
}

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('canvas[data-preview]').forEach((canvas) => {
    preview(canvas)
  })
})
