import { Controller } from "@hotwired/stimulus"

export default class HelloController extends Controller {
  connect() {
    this.element.textContent = "Hello World!"
  }

  disconnect() {
    // Cleanup if needed
  }

  // Example method to demonstrate testing
  greet(name = "World") {
    const greeting = `Hello, ${name}!`
    this.element.textContent = greeting
    return greeting
  }

  // Another method for testing
  updateElement(content) {
    if (this.element) {
      this.element.textContent = content
    }
  }
}