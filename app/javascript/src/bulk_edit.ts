function handleSelectAllChange(event) {
  event.preventDefault();
  document.querySelectorAll('[data-bulk-item]').forEach((cb) => {
    cb.checked = !cb.checked
  });
}

document.addEventListener('turbolinks:load', () => {
  const bulkSelector = document.querySelector('input[name="bulk_select_all"]');
  if (bulkSelector) {
    bulkSelector.removeEventListener("change", handleSelectAllChange);
    bulkSelector.addEventListener("change", handleSelectAllChange);
  }
})
