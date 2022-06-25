import { ObjectPreview } from './preview'

declare global {
  interface Window {
    tagInputs: Array<JQuery<HTMLElement>>
  }
  interface HTMLCanvasElement {
    renderer: ObjectPreview
  }
}
