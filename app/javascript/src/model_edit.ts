document.addEventListener('DOMContentLoaded', () => {
  window.tagInputs = []
  $('select[data-selectize]').each(
    function () {
      const tagInput = $(this).selectize({
        addPrecedence: true,
        create: true,
        plugins: ['remove_button']
      })
      window.tagInputs.push(tagInput)
    }
  )
})
