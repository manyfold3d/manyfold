// Turbo and Stimulus
import '@hotwired/turbo-rails'
import 'controllers/index'

import Rails from '@rails/ujs'
import Cocooned from '@notus.sh/cocooned'

document.addEventListener('DOMContentLoaded', () => {
  // Legacy Rails UJS
  Rails.start()
  // Cocooned only wants initializing once, it seems
  Cocooned.start()
})
