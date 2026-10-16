import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="kiri-moto"
export default class extends Controller {
  static values = {
    url: String
  }

  connect () {
  }
}
