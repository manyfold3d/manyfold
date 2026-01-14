// Turbo and Stimulus
import '@hotwired/turbo-rails'
import './controllers/index'

import Rails from '@rails/ujs'
import 'masonry-layout'

import 'altcha/external'
import 'altcha/i18n/cs'
import 'altcha/i18n/de'
import 'altcha/i18n/en'
import 'altcha/i18n/es-es'
import 'altcha/i18n/fr-fr'
import 'altcha/i18n/ja'
import 'altcha/i18n/nl'
import 'altcha/i18n/pl'

document.addEventListener('DOMContentLoaded', () => {
  // Legacy Rails UJS
  Rails.start()
})
