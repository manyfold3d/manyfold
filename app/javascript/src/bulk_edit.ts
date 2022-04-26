function updateTagOptions(tags, input, addTags = true) {
  tags.forEach((tag) => {
    if (addTags) {
      input.addOption({value: tag, text: tag});
    } else {
      input.removeOption({value: tag, text: tag});
    }
  });
  input.refreshOptions(false);
}

function getTags(modelId) {
  const tagLinks = document.querySelectorAll('[data-bulk-item-tags="' + modelId + '"]')
  return Array.prototype.slice.call(tagLinks).map((tag) => ( tag.innerText ))
}

function handleCheckboxChange (event): void {
  event.preventDefault()
  if (event.target.name == "bulk-select-all") {
    document.querySelectorAll('[data-bulk-item]').forEach((cb): boolean => {
      cb.checked = !(cb.checked as boolean)
    })
  } else {
    const modelId = event.target.getAttribute('data-bulk-item')
    if (modelId) {
      const tags = getTags(modelId)
      if (tags && window.tagInputs) {
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
