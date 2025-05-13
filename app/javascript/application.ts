
// Entry point for the build script in your package.json
import Rails from '@rails/ujs'
import $ from 'jquery' // Just needed for activeadmin and a coyoke couple of other bits
import '@hotwired/turbo-rails'

import 'masonry-layout'

import Cocooned from '@notus.sh/cocooned'

import 'src/bulk_edit'
import 'src/model_edit'
import 'src/tag'
import 'src/file_size_validation'
import 'src/passwords'
import 'src/library_form'
import 'controllers/index'

// Load i18n definitions
import { I18n } from 'i18n-js'
import locales from 'src/locales.json'
window.i18n = new I18n(locales)

window.$ = $

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
