// Entry point for the build script in your package.json

import Rails from '@rails/ujs'
import 'bootstrap'

import 'src/preview'
import 'src/bulk_edit'
import 'src/model_edit'

import '@nathanvda/cocoon'
import '@selectize/selectize/dist/js/standalone/selectize.min.js'

Rails.start()
