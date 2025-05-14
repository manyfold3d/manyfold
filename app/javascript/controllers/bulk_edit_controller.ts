import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="bulk-edit"
export default class extends Controller {
  connect (): void {
  }

  updateTagOptions (tags: string[], input, addTags = true): void {
    tags.forEach((tag) => {
      if (addTags) {
        input.tomselect.addOption({ value: tag, text: tag })
      } else {
        input.tomselect.removeOption({ value: tag, text: tag })
      }
    })
    input.tomselect.refreshOptions(false)
  }

  getTags (modelId: string): string[] {
    const selector = `[data-bulk-item-tags="${modelId}"]`
    const tagLinks = document.querySelectorAll(
      selector
    )
    return Array.prototype.slice
      .call(tagLinks)
      .map((tag: HTMLAnchorElement) => tag.textContent)
  }

  updateTagList (modelId: string, add: boolean): void {
    const tags = this.getTags(modelId)
    if (tags.length > 0) {
      this.updateTagOptions(tags, document.querySelector('select[name="remove_tags[]"]'), add)
    }
  }

  handleCheckboxChange (event): void {
    const target = event.target as HTMLInputElement
    event.preventDefault()
    // the bulk select checkbox has been selected
    if (target.name === 'bulk-select-all') {
      document
        .querySelectorAll('[data-bulk-item]')
        .forEach((checkbox: HTMLInputElement) => {
          const modelId = checkbox.getAttribute('data-bulk-item')
          if (modelId != null) {
            this.updateTagList(modelId, target.checked)
          }
          checkbox.checked = target.checked
        })
    } else {
      // a single checkbox item has been selected.
      const modelId = target.getAttribute('data-bulk-item') as string
      if (modelId != null) {
        this.updateTagList(modelId, target.checked)
      }
    }
  }
}
