import * as Comlink from 'comlink';

type UnifiedEvent = {
	type: string;
	altKey? : boolean;
	ctrlKey? : boolean;
	metaKey? : boolean;
	shiftKey? : boolean;
	button? : number;
	buttons? : number;
	clientX? : number;
	clientY? : number;
	pageX? : number;
	pageY? : number;
	pointerType? : string;
	deltaX? : number;
	deltaY? : number;
	keyCode? : number;
}

Comlink.transferHandlers.set("EVENT", {
	canHandle: (obj) : boolean => obj instanceof Event,
	serialize: (ev : Event) => {
		var serializedEvent : UnifiedEvent = { type: ev.type }
		if (ev instanceof PointerEvent)
			serializedEvent = {
				altKey: ev.altKey,
				ctrlKey: ev.ctrlKey,
				metaKey: ev.metaKey,
				shiftKey: ev.shiftKey,
				button: ev.button,
				buttons: ev.buttons,
				clientX: ev.clientX,
				clientY: ev.clientY,
				pageX: ev.pageX,
				pageY: ev.pageY,
				pointerType: ev.pointerType,
				...serializedEvent
			}
		if (ev instanceof WheelEvent)
			serializedEvent = {
				deltaX: ev.deltaX,
				deltaY: ev.deltaY,
				...serializedEvent
			}
		if (ev instanceof KeyboardEvent)
			serializedEvent = {
				altKey: ev.altKey,
				ctrlKey: ev.ctrlKey,
				metaKey: ev.metaKey,
				shiftKey: ev.shiftKey,
				keyCode: ev.keyCode,
				...serializedEvent
			}
		return [serializedEvent, []];
	},
	deserialize: (obj) => obj,
});
