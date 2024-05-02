import * as bootstrap from 'bootstrap'

document.addEventListener('DOMContentLoaded', () => {
  let paused = false
  let manual = false
  const carouselElement = document.querySelector('#imageCarousel')
  if (carouselElement != null) {
    new bootstrap.Carousel(carouselElement, { /* eslint no-new: 0 */
      interval: 5000,
      pause: false
    })

    function togglePause (): void {
      manual = true
      onPause(!paused, true)
    }

    function onPause (pause: boolean, updateState: boolean): void {
      if (pause) {
        $('#imageCarousel').carousel('pause')
        $('#imageCarouselInner').attr('aria-live', 'polite')
        if (updateState) {
          paused = true
          $('#rotationControlIcon').addClass('bi-play')
          $('#rotationControlIcon').removeClass('bi-pause')
        }
      } else {
        $('#imageCarousel').carousel('cycle')
        $('#imageCarouselInner').attr('aria-live', 'off')
        if (updateState) {
          paused = false
          $('#rotationControlIcon').addClass('bi-pause')
          $('#rotationControlIcon').removeClass('bi-play')
        }
      }
    }

    carouselElement.addEventListener('slid.bs.carousel', function (event) {
      $('.carousel-indicators > button').removeAttr('aria-disabled')
      $(`.carousel-indicators > button:nth-child(${event.to + 1})`).attr('aria-disabled', 'true')
    })

    $('#rotationControl').click(togglePause)
    $('#imageCarousel').mouseenter(function () { if (!manual) { onPause(true, false) } })
    $('#imageCarousel').mouseleave(function () { if (!manual) { onPause(false, false) } })
    // $('#imageCarousel').focus(function () { manual = true; onPause(true, true) }});
  }
})
