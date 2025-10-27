import { Controller } from '@hotwired/stimulus'
import { driver } from 'driver.js'

// Connects to data-controller="basic-tour"
export default class extends Controller {
  driverObject = null
  completed = []

  connect (): void {
    // Find tour elements in page
    const tourElements = document.querySelectorAll('[data-tour-title]')
    if (tourElements.length > 0) {
      // Create steps for each element
      const tourSteps = [...tourElements].map((stepElement: HTMLElement) => (
        {
          element: '#' + stepElement.id,
          popover: {
            title: stepElement.dataset.tourTitle,
            description: stepElement.dataset.tourDescription
          }
        }
      ))
      // Create driver object
      const driverObj = driver({
        showProgress: true,
        steps: tourSteps
      })
      // Start
      driverObj.drive()
    }
  }
}
