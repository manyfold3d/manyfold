import { ObjectPreview } from './preview'

declare global {
  interface Window {
    tagInputs: Array<JQuery<HTMLElement>>
    i18n
  }
  interface HTMLCanvasElement {
    renderer: ObjectPreview
  }
}
