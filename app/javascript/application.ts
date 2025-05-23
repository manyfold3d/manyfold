// Turbo and Stimulus
import '@hotwired/turbo-rails'
import 'controllers/index'

import Rails from '@rails/ujs'

document.addEventListener('DOMContentLoaded', () => {
  // Legacy Rails UJS
  Rails.start()
})
