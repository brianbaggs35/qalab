import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="upload"
export default class extends Controller {
  static targets = ["form", "fileInput", "submitButton", "progressBar", "progressContainer"]

  connect() {
    console.log("Upload controller connected")
    // Add event listeners
    this.formTarget.addEventListener('submit', this.handleSubmit.bind(this))
    this.fileInputTarget.addEventListener('change', this.handleFileChange.bind(this))
    
    // Ensure button is initially disabled
    this.submitButtonTarget.disabled = true
  }

  handleFileChange(event) {
    console.log("File change event triggered")
    const input = event.target
    const file = input.files?.[0]
    
    if (file) {
      console.log("File selected:", file.name, file.type)
      
      // Validate file type
      if (!file.name.toLowerCase().endsWith('.xml')) {
        alert('Please select a valid XML file')
        input.value = ''
        this.submitButtonTarget.disabled = true
        this.submitButtonTarget.textContent = 'Upload Test Results'
        return
      }

      // File is valid - enable button
      this.submitButtonTarget.textContent = `Upload ${file.name}`
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.classList.remove('btn-disabled')
      
      console.log("Button enabled for file:", file.name)
    } else {
      console.log("No file selected")
      this.submitButtonTarget.textContent = 'Upload Test Results'
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.classList.add('btn-disabled')
    }
  }

  handleSubmit(event) {
    console.log("Form submit triggered")
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
        
        // Parse response to get redirect URL or use default
        let redirectUrl = '/automated_testing/results'
        try {
          if (xhr.responseURL && xhr.responseURL.includes('automated_testing/results')) {
            redirectUrl = xhr.responseURL
          }
        } catch (e) {
          console.log("Using default redirect URL")
        }
        
        // Redirect after a short delay
        setTimeout(() => {
          window.location.href = redirectUrl
        }, 2000)
      } else if (xhr.status === 422) {
        // Handle validation errors
        console.error("Upload validation failed")
        try {
          // Try to parse error response for specific error messages
          const response = xhr.responseText
          if (response.includes('must be an XML file')) {
            this.showError('Please upload a valid XML file.')
          } else if (response.includes('must be less than 50MB')) {
            this.showError('File size must be less than 50MB.')
          } else {
            this.showError('Upload failed due to validation errors. Please check your file and try again.')
          }
        } catch (e) {
          this.showError('Upload failed due to validation errors. Please check your file and try again.')
        }
      } else {
        console.error("Upload failed with status:", xhr.status)
        this.showError('Upload failed. Please try again.')
      }
    })

    // Handle errors
    xhr.addEventListener('error', () => {
      console.error("Upload error occurred")
      this.showError('Upload failed. Please check your connection and try again.')
    })

    // Send the request
    xhr.open('POST', this.formTarget.action)
    
    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    if (csrfToken) {
      xhr.setRequestHeader('X-CSRF-Token', csrfToken)
    }
    
    console.log("Sending upload request...")
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

  updateProgress(percent) {
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

  showError(message) {
    console.error("Upload error:", message)
    this.progressContainerTarget.classList.add('hidden')
    this.submitButtonTarget.disabled = false
    this.submitButtonTarget.textContent = 'Upload Test Results'
    this.submitButtonTarget.classList.remove('btn-success')
    this.submitButtonTarget.classList.add('btn-primary')
    alert(message)
  }
}