import { EventDispatcher } from 'three'

export class DOMElementProxy extends EventDispatcher {
	style = { touchAction: '' }

	constructor () {
		super();
	}
	handleEvent (event) {
		console.log(event)
		this.dispatchEvent(event);
	}
	getRootNode () {
		return this;
	}
	setPointerCapture () {};
	releasePointerCapture () { };
}
