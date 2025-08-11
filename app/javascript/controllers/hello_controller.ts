import { Controller } from "@hotwired/stimulus"

export default class HelloController extends Controller {
  declare readonly element: HTMLElement

  connect(): void {
    this.element.textContent = "Hello World!"
  }

  disconnect(): void {
    // Cleanup if needed
  }

  // Example method to demonstrate testing
  greet(name: string = "World"): string {
    const greeting = `Hello, ${name}!`
    this.element.textContent = greeting
    return greeting
  }

  // Another method for testing
  updateElement(content: string): void {
    if (this.element) {
      this.element.textContent = content
    }
  }
}