document.addEventListener('turbolinks:load', () => {
  window.tagInputs = []
  $('input[data-tags-edit]').each(
    function () {
      const tagInput = $(this).selectize({
        create: true,
        sortField: 'text',
        maxItems: null
      })
      window.tagInputs.push(tagInput)
    }
  )
})
