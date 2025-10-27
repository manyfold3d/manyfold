import { Controller } from "@hotwired/stimulus"
import { driver } from "driver.js";


// Connects to data-controller="basic-tour"
export default class extends Controller {

  connect () {
    // Find tour elements in page
    const tourElements = document.querySelectorAll("[data-tour-title]");
    const tourSteps = [...tourElements].map((stepElement: HTMLElement) => (
      {
        element: "#" + stepElement.id,
        popover: {
          title: stepElement.dataset["title"],
          description: stepElement.dataset["description"]
        }
      }
    ));
    const driverObj = driver({
      showProgress: true,
      steps: tourSteps
    });
    if ((this.element as HTMLElement).dataset["tourAutostart"])
      driverObj.drive();
  }
}
