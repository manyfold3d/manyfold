import { Controller } from '@hotwired/stimulus'
import { driver, Driver, DriveStep, Config, State } from 'driver.js'

// Connects to data-controller="basic-tour"
export default class extends Controller {
  driverObject: Driver | null = null
  completed: string[] = []

  connect (): void {
    // Find uncompleted tour elements in page
    const tourElements = document.querySelectorAll('[data-tour-id-completed="false"]')
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
      this.driverObject = driver({
        onHighlighted: this.onHighlighted.bind(this),
        onDestroyStarted: this.onDestroyStarted.bind(this),
        showProgress: true,
        steps: tourSteps
      })
      // Start
      this.driverObject.drive()
    }
  }

  onHighlighted (element: Element, step: DriveStep, options: { config: Config, state: State, driver: Driver }): void {
    this.completed.push(element.id)
  }

  onDestroyStarted (): void {
    // Store tour state back into current user
    const xhr = new XMLHttpRequest()
    xhr.open('PATCH', '/users.json', true)
    xhr.setRequestHeader('Content-Type', 'application/json')
    xhr.send(JSON.stringify({
      user: {
        tour_state: {
          completed: {
            add: this.completed
          }
        }
      }
    }))
    // Done, close the tour
    this.driverObject?.destroy()
  }
}
