function updateTagOptions (tags, input, addTags = true): void {
  tags.forEach((tag) => {
    if (addTags) {
      input.addOption({ value: tag, text: tag })
    } else {
      input.removeOption({ value: tag, text: tag })
    }
  })
  input.refreshOptions(false)
}

function getTags (modelId: string): string[] {
  const selector = `[data-bulk-item-tags="${modelId}"]`
  const tagLinks = document.querySelectorAll(selector)
  return Array.prototype.slice.call(tagLinks).map((tag) => (tag.innerText))
}

function handleCheckboxChange (event): void {
  event.preventDefault()
  if (event.target.name === 'bulk-select-all') {
    document.querySelectorAll('[data-bulk-item]').forEach((cb): boolean => {
      cb.checked = !(cb.checked as boolean)
    })
  } else {
    const modelId = event.target.getAttribute('data-bulk-item') as string
    if (modelId != null) {
      const tags = getTags(modelId)
      if (tags.length > 0 && window.tagInputs != null) {
        window.tagInputs.forEach((input) => {
          updateTagOptions(tags, input[0].selectize, event.target.checked)
        })
      }
    }
  }
}

document.addEventListener('turbolinks:load', () => {
  const bulkEditTable = document.querySelector('[data-bulk-edit]')
  if (bulkEditTable != null) {
    bulkEditTable.removeEventListener('change', handleCheckboxChange)
    bulkEditTable.addEventListener('change', handleCheckboxChange)
  }
})
