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
			onPause(paused)
		}

		function onPause (pause) {
			if (pause) {
				$('#imageCarousel').carousel("pause");
				$('#rotationControlIcon').addClass("bi-play")
				$('#rotationControlIcon').removeClass("bi-pause")
			}
			else {
				$('#imageCarousel').carousel("cycle");
				$('#rotationControlIcon').addClass("bi-pause")
				$('#rotationControlIcon').removeClass("bi-play")
			}
			$('#imageCarousel').toggleClass('fa-play fa-pause');
		}

		$('#rotationControl').click(togglePause);
		$('#imageCarousel').mouseenter(function () { if (!manual) { $('#imageCarousel').carousel("pause") } });
		$('#imageCarousel').mouseleave(function () { if (!manual) { $('#imageCarousel').carousel("cycle") } });
		$('#imageCarousel').focus(function () { manual = true; onPause(true) });
	}
});
