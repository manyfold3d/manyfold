import { EventDispatcher } from 'three'

export class CanvasProxy extends EventDispatcher {
	style = { touchAction: '' }
	clientWidth;
	clientHeight;
	realCanvas: HTMLCanvasElement;

	constructor (canvas: HTMLCanvasElement) {
		super();
		this.realCanvas = canvas
	}
	resize (width, height) {
		this.clientWidth = width;
		this.clientHeight = height;
		this.realCanvas.width = width;
		this.realCanvas.height = height;
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
