
// Entry point for the build script in your package.json
import Rails from '@rails/ujs'
import '@hotwired/turbo-rails'

import 'masonry-layout'

import Cocooned from '@notus.sh/cocooned'

// Include stimulus controllers
import 'controllers/index'

document.addEventListener('DOMContentLoaded', () => {
  Rails.start()
  Cocooned.start()
})
