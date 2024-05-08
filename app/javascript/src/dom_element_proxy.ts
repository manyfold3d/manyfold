import { EventDispatcher } from 'three'

export class DOMElementProxy extends EventDispatcher {
	style = { touchAction: '' }
	clientWidth;
	clientHeight;
	canvas: HTMLCanvasElement = null

	constructor (canvas) {
		super();
		this.canvas = canvas
	}
	resize (width, height) {
		this.clientWidth = width;
		this.clientHeight = height;
		this.canvas.width = width;
		this.canvas.height = height;
	}
	handleEvent (event) {
		this.dispatchEvent(event);
	}

	// Pretend we can handle capture events
	getRootNode () {
		return this;
	}
	setPointerCapture () {};
	releasePointerCapture () { };
}
