document.addEventListener('DOMContentLoaded', () => {
  window.tagInputs = []
  $('input[data-tags-edit]').each(
    function () {
      const tagInput = $(this).selectize({
        addPrecedence: true,
        create: true,
        sortField: 'text',
        plugins: ['remove_button']
      })
      window.tagInputs.push(tagInput)
    }
  )
})
