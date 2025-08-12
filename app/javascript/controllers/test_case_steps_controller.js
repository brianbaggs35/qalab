import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="test-case-steps"
export default class extends Controller {
  static targets = ["stepsContainer", "stepInput", "stepsList", "hiddenInput"]
  
  connect() {
    this.steps = []
    this.updateHiddenInput()
  }

  addStep(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.createStep()
    }
  }

  createStep() {
    const input = this.stepInputTarget
    const stepText = input.value.trim()
    
    if (stepText === "") return
    
    this.steps.push(stepText)
    this.renderSteps()
    this.updateHiddenInput()
    
    // Clear input and focus
    input.value = ""
    input.focus()
  }

  removeStep(event) {
    const index = parseInt(event.target.dataset.index)
    this.steps.splice(index, 1)
    this.renderSteps()
    this.updateHiddenInput()
  }

  renderSteps() {
    const container = this.stepsListTarget
    container.innerHTML = ""
    
    this.steps.forEach((step, index) => {
      const stepElement = document.createElement("div")
      stepElement.className = "flex items-start gap-3 p-4 bg-base-200 rounded-lg group hover:bg-base-300 transition-colors"
      
      stepElement.innerHTML = `
        <div class="flex items-center justify-center w-8 h-8 bg-primary text-primary-content rounded-full text-sm font-bold flex-shrink-0 mt-0.5">
          ${index + 1}
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-base-content break-words">${this.escapeHtml(step)}</p>
        </div>
        <button type="button" 
                class="btn btn-ghost btn-sm btn-circle opacity-0 group-hover:opacity-100 transition-opacity text-error hover:bg-error/10"
                data-action="click->test-case-steps#removeStep"
                data-index="${index}"
                title="Remove step">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      `
      
      container.appendChild(stepElement)
    })
  }

  updateHiddenInput() {
    this.hiddenInputTarget.value = JSON.stringify(this.steps)
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}