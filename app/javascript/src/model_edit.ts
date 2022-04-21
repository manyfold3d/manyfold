document.addEventListener('turbolinks:load', () => {
  const tagsInput = $('input[name="model[tags]"]')
  if (tagsInput != null) {
    tagsInput.selectize({
      create: true,
      sortField: 'text'
    })
  }
})
