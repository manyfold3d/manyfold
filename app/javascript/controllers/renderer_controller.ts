import { Controller } from '@hotwired/stimulus'
import { ObjectPreview } from '../src/object_preview'

// Connects to data-controller="renderer"
export default class extends Controller {
  connect (): void {
    const preview = new ObjectPreview(this.element)
    void (async () => {
      await preview.initialize()
    })() // Wrap up the promise, we don't want it
  }
}
