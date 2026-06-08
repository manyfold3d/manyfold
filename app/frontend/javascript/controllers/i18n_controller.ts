import { Controller } from '@hotwired/stimulus'

// Load i18n definitions
import { I18n } from 'i18n-js'
import locales from '../src/locales.json'

// Connects to data-controller="i18n"
export default class extends Controller {
  connect (): void {
    window.i18n = new I18n(locales)
    window.i18n.locale = (this.element as HTMLElement).lang ?? 'en'
  }
}
