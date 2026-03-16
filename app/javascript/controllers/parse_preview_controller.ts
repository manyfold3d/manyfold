import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="parse-preview"
export default class extends Controller {
  parsePreviewFrame: HTMLFrameElement | null
  templateInput: HTMLInputElement | null
  parseMetadataInput: HTMLInputElement | null

  connect (): void {
    this.parsePreviewFrame = this.element.querySelector('#parse-preview')
    this.pathInput = this.element.querySelector('#library_path')
    this.templateInput = this.element.querySelector('#library_path_template')
    this.parseMetadataInput = this.element.querySelector('#library_parse_metadata_from_path')
    this.handleChange()
  }

  handleChange (): void {
    if ((this.parsePreviewFrame != null) && (this.templateInput != null) && (this.parseMetadataInput != null) && (this.parsePreviewFrame.dataset.src != null)) {
      let url = `${this.parsePreviewFrame.dataset.src}?template=${encodeURIComponent(this.templateInput.value)}&enabled=${this.parseMetadataInput.checked ? 'true' : 'false'}`
      if (this.pathInput != null) {
        url += `&path=${encodeURIComponent(this.pathInput.value)}`
      }
      this.parsePreviewFrame.src = url
    }
  }
}
