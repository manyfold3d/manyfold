import * as bootstrap from 'bootstrap'

document.addEventListener('DOMContentLoaded', () => {
	var paused = false;
	var manual = false;
	const myCarouselElement = document.querySelector('#imageCarousel')
	if (myCarouselElement) {
		const carousel = new bootstrap.Carousel(myCarouselElement, {
			interval: 1000,
			pause: false
		});

		function togglePause () {
			manual = true
			paused = (paused) ? false : true;
			onPause(paused, true)
		}

		function onPause (pause, updateIcon) {
			if (pause) {
				$('#imageCarousel').carousel("pause");
				$('#imageCarouselInner').attr("aria-live", "polite")
				if (updateIcon) {
					$('#rotationControlIcon').addClass("bi-play")
					$('#rotationControlIcon').removeClass("bi-pause")
				}
			}
			else {
				$('#imageCarousel').carousel("cycle");
				$('#imageCarouselInner').attr("aria-live", "off")
				if (updateIcon) {
					$('#rotationControlIcon').addClass("bi-pause")
					$('#rotationControlIcon').removeClass("bi-play")
				}
			}
		}

		$('#rotationControl').click(togglePause);
		$('#imageCarousel').mouseenter(function () { if (!manual) { onPause(true, false) } });
		$('#imageCarousel').mouseleave(function () { if (!manual) { onPause(false, false) } });
		$('#rotationControl').focus(function () { manual = true; onPause(true, true) });
	}
});
