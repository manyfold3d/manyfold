
// Entry point for the build script in your package.json
import Rails from '@rails/ujs'
import '@hotwired/turbo-rails'

import 'masonry-layout'

import Cocooned from '@notus.sh/cocooned'

// Include stimulus controllers
import 'controllers/index'

// Load i18n definitions
import { I18n } from 'i18n-js'
import locales from 'src/locales.json'
window.i18n = new I18n(locales)

const manyfoldReady = new Event('ManyfoldReady')

document.addEventListener('DOMContentLoaded', () => {
  window.i18n.locale = document.querySelector('html')?.lang ?? 'en'
  Rails.start()
  Cocooned.start()
  document.dispatchEvent(new Event('turbo:load'))
})

document.addEventListener('turbo:load', () => {
  document.dispatchEvent(manyfoldReady)
})
