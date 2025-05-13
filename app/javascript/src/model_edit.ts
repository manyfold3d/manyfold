import TomSelect from 'tom-select'
import type { TomInput } from 'tom-select/dist/cjs/types'

document.addEventListener('ManyfoldReady', () => {
  document.querySelectorAll('select[data-tom-select]').forEach(
    (element: TomInput) => {
      if (element.tomselect != null) { return }
      new TomSelect(element, { // eslint-disable-line no-new
        addPrecedence: true,
        create: true,
        plugins: ['remove_button'],
        selectOnTab: true,
        onItemAdd: function () {
          this.setTextboxValue('')
          this.refreshOptions()
        }
      })
    }
  )
  // Editable names (and other fields):
  $('[contenteditable=true]').focus(function () {
    $(this).data('initialText', $(this).text().trim())
  })
  $('[contenteditable=true]').blur(async function () {
    if ($(this).data('initialText') !== $(this).text().trim()) {
      console.log($(this).data('field'), ' changed: ', $(this).text().trim())
      const postvar: any = {}
      postvar[$(this).data('field')] = $(this).text().trim()
      postvar._method = 'patch'
      postvar.authenticity_token = $('meta[name="csrf-token"]').attr('content')
      await $.post($(this).data('path'), postvar, function (result) { console.log(result.status) }).promise()
    }
  })
})
