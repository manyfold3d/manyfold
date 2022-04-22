document.addEventListener('turbolinks:load', () => {
  window.tagInputs = [];
  $('input[name="tags"]').each(
    function() {
      const tagInput = $(this).selectize({
        create: true,
        sortField: 'text',
        maxItems: null
      })
      window.tagInputs.push(tagInput)
    }
  )
})
