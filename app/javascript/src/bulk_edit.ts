function handleSelectAllChange (event): void {
  event.preventDefault()
  document.querySelectorAll('[data-bulk-item]').forEach((cb): boolean => {
    cb.checked = !(cb.checked as boolean)
  })
}

document.addEventListener('turbolinks:load', () => {
  const bulkSelector = document.querySelector('input[name="bulk_select_all"]')
  if (bulkSelector != null) {
    bulkSelector.removeEventListener('change', handleSelectAllChange)
    bulkSelector.addEventListener('change', handleSelectAllChange)
  }
})
