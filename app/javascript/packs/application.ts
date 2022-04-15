// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

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

import '@nathanvda/cocoon'

Rails.start()
Turbolinks.start()
ActiveStorage.start()
