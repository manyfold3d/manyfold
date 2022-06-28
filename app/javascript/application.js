// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import Rails from '@rails/ujs'
import Turbolinks from 'turbolinks'
import * as ActiveStorage from '@rails/activestorage'
import 'channels'

import 'controllers'
import 'bootstrap/dist/js/bootstrap'
import 'bootstrap/dist/css/bootstrap'

import 'bootstrap-icons/font/bootstrap-icons.css'
import 'src/preview'
import 'src/bulk_edit'
import 'src/model_edit'

import '@nathanvda/cocoon'
import '@selectize/selectize/dist/js/standalone/selectize.min.js'
import '@selectize/selectize/dist/css/selectize.bootstrap5.css'
import '@hotwired/turbo-rails'

Rails.start()
Turbolinks.start()
ActiveStorage.start()
