function setDetailOpenStatus (item: string): void {
  if (item.includes('details-')) {
    const id = item.split('details-')[1]
    const status = window.localStorage.getItem(item)
    if (status === 'open') {
      $(`#${id}`).attr('open', 'open')
    }
  }
}

$(document).ready(
  function () {
    $('details').on('toggle', function (event): void {
      const id = $(this).attr('id') ?? ''
      const isOpen = $(this).attr('open') ?? ''
      console.log(id, isOpen)
      window.localStorage.setItem(`details-${id}`, isOpen)
    })
    for (let i = 0; i < localStorage.length; i++) {
      setDetailOpenStatus(localStorage.key(i))
    }
  }
)
