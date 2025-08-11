import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="alert"
export default class extends Controller<HTMLElement> {
  static values = { autoClose: Boolean }

  declare readonly autoCloseValue: boolean
  private autoCloseTimeout?: number

  connect() {
    if (this.autoCloseValue) {
      this.autoCloseTimeout = window.setTimeout(() => {
        this.close()
      }, 5000) // Auto-close after 5 seconds
    }
  }

  disconnect() {
    if (this.autoCloseTimeout) {
      clearTimeout(this.autoCloseTimeout)
    }
  }

  close() {
    // Fade out animation
    this.element.style.transition = "opacity 0.3s ease-out, transform 0.3s ease-out"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateX(100%)"
    
    // Remove element after animation
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}