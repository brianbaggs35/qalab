import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="upload"
export default class extends Controller<HTMLElement> {
  static targets = ["form", "fileInput", "submitButton", "progressBar", "progressContainer"]

  declare readonly formTarget: HTMLFormElement
  declare readonly fileInputTarget: HTMLInputElement
  declare readonly submitButtonTarget: HTMLButtonElement
  declare readonly progressBarTarget: HTMLElement
  declare readonly progressContainerTarget: HTMLElement

  connect() {
    // Add event listeners
    this.formTarget.addEventListener('submit', this.handleSubmit.bind(this))
    this.fileInputTarget.addEventListener('change', this.handleFileChange.bind(this))
  }

  handleFileChange(event: Event) {
    const input = event.target as HTMLInputElement
    const file = input.files?.[0]
    
    if (file) {
      // Validate file type
      if (!file.name.toLowerCase().endsWith('.xml')) {
        alert('Please select a valid XML file')
        input.value = ''
        return
      }

      // Update submit button text
      this.submitButtonTarget.textContent = `Upload ${file.name}`
      this.submitButtonTarget.disabled = false
    } else {
      this.submitButtonTarget.textContent = 'Upload Test Results'
      this.submitButtonTarget.disabled = true
    }
  }

  handleSubmit(event: Event) {
    event.preventDefault()
    
    const file = this.fileInputTarget.files?.[0]
    if (!file) {
      alert('Please select a file to upload')
      return
    }

    // Show progress bar
    this.showProgress()
    
    // Create FormData
    const formData = new FormData(this.formTarget)
    
    // Create XMLHttpRequest for progress tracking
    const xhr = new XMLHttpRequest()
    
    // Track upload progress
    xhr.upload.addEventListener('progress', (e) => {
      if (e.lengthComputable) {
        const percentComplete = (e.loaded / e.total) * 100
        this.updateProgress(percentComplete)
      }
    })

    // Handle completion
    xhr.addEventListener('load', () => {
      if (xhr.status === 200 || xhr.status === 302) {
        // Show success message
        this.showSuccess()
        
        // Redirect after a short delay
        setTimeout(() => {
          window.location.href = '/automated_testing/results'
        }, 2000)
      } else {
        this.showError('Upload failed. Please try again.')
      }
    })

    // Handle errors
    xhr.addEventListener('error', () => {
      this.showError('Upload failed. Please check your connection and try again.')
    })

    // Send the request
    xhr.open('POST', this.formTarget.action)
    
    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    if (csrfToken) {
      xhr.setRequestHeader('X-CSRF-Token', csrfToken)
    }
    
    xhr.send(formData)
  }

  showProgress() {
    this.progressContainerTarget.classList.remove('hidden')
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.innerHTML = `
      <span class="loading loading-spinner loading-sm"></span>
      Processing...
    `
  }

  updateProgress(percent: number) {
    this.progressBarTarget.style.width = `${percent}%`
    this.progressBarTarget.textContent = `${Math.round(percent)}%`
  }

  showSuccess() {
    this.progressBarTarget.style.width = '100%'
    this.progressBarTarget.textContent = '100%'
    this.submitButtonTarget.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
      </svg>
      Upload Complete!
    `
    this.submitButtonTarget.classList.remove('btn-primary')
    this.submitButtonTarget.classList.add('btn-success')
  }

  showError(message: string) {
    this.progressContainerTarget.classList.add('hidden')
    this.submitButtonTarget.disabled = false
    this.submitButtonTarget.textContent = 'Upload Test Results'
    alert(message)
  }
}