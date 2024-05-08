import * as Comlink from 'comlink';

export default Comlink.transferHandlers.set("EVENT", {
	canHandle: (obj) => obj instanceof Event,
	serialize: (ev) => {
		return [
			{
				type: ev.type,
				target: {
					id: ev.target.id,
					classList: [...ev.target.classList],
				},
				// Shared
				altKey: ev.altKey,
				ctrlKey: ev.ctrlKey,
				metaKey: ev.metaKey,
				shiftKey: ev.shiftKey,
				// MouseEvent properties
				button: ev.button,
				buttons: ev.buttons,
				clientX: ev.clientX,
				clientY: ev.clientY,
				pageX: ev.pageX,
				pageY: ev.pageY,
				pointerType: ev.pointerType,
				// WheelEvent properties
				deltaX: ev.deltaX,
				deltaY: ev.deltaY,
				// KeyboardEvent properties
				keyCode: ev.keyCode,
			},
			[],
		];
	},
	deserialize: (obj) => obj,
});
