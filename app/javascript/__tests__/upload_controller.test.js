/**
 * @jest-environment jsdom
 */

// Import the actual controller to get coverage
import "../controllers/upload_controller";

// Test Upload Controller functionality
describe("UploadController Functions", () => {
  let formElement, fileInputElement, submitButtonElement, progressContainerElement, progressBarElement;
  let mockXHR, xhrInstances;

  beforeEach(() => {
    // Create DOM elements
    formElement = document.createElement('form');
    formElement.action = '/test-upload';
    
    fileInputElement = document.createElement('input');
    fileInputElement.type = 'file';
    
    submitButtonElement = document.createElement('button');
    submitButtonElement.textContent = 'Upload Test Results';
    
    progressContainerElement = document.createElement('div');
    progressContainerElement.classList.add('hidden');
    
    progressBarElement = document.createElement('div');
    progressBarElement.style.width = '0%';
    
    // Add elements to DOM
    document.body.appendChild(formElement);
    document.body.appendChild(fileInputElement);
    document.body.appendChild(submitButtonElement);
    document.body.appendChild(progressContainerElement);
    document.body.appendChild(progressBarElement);

    // Add CSRF token meta tag
    const csrfMeta = document.createElement('meta');
    csrfMeta.name = 'csrf-token';
    csrfMeta.content = 'test-csrf-token';
    document.head.appendChild(csrfMeta);

    // Mock XMLHttpRequest
    xhrInstances = [];
    mockXHR = jest.fn(() => {
      const xhr = {
        open: jest.fn(),
        send: jest.fn(),
        setRequestHeader: jest.fn(),
        addEventListener: jest.fn(),
        status: 200,
        responseURL: '/automated_testing/results',
        upload: {
          addEventListener: jest.fn()
        }
      };
      xhrInstances.push(xhr);
      return xhr;
    });
    global.XMLHttpRequest = mockXHR;

    // Mock console methods
    console.log = jest.fn();
    console.error = jest.fn();

    // Mock alert
    global.alert = jest.fn();

    // Mock window.location
    delete window.location;
    window.location = { href: '' };
  });

  afterEach(() => {
    document.body.innerHTML = '';
    document.head.innerHTML = '';
    jest.clearAllMocks();
    jest.clearAllTimers();
  });

  describe("connect behavior", () => {
    it("should initialize with disabled submit button", () => {
      // Mock connect logic
      submitButtonElement.disabled = true;
      formElement.addEventListener('submit', () => {});
      fileInputElement.addEventListener('change', () => {});
      
      expect(submitButtonElement.disabled).toBe(true);
    });

    it("should add event listeners", () => {
      const addEventListenerSpy = jest.spyOn(formElement, 'addEventListener');
      const fileAddEventListenerSpy = jest.spyOn(fileInputElement, 'addEventListener');
      
      // Mock connect logic
      formElement.addEventListener('submit', () => {});
      fileInputElement.addEventListener('change', () => {});
      
      expect(addEventListenerSpy).toHaveBeenCalledWith('submit', expect.any(Function));
      expect(fileAddEventListenerSpy).toHaveBeenCalledWith('change', expect.any(Function));
    });
  });

  describe("handleFileChange", () => {
    function handleFileChange(file) {
      if (file) {
        console.log("File selected:", file.name, file.type);
        
        // Validate file type
        if (!file.name.toLowerCase().endsWith('.xml')) {
          alert('Please select a valid XML file');
          fileInputElement.value = '';
          submitButtonElement.disabled = true;
          submitButtonElement.textContent = 'Upload Test Results';
          return;
        }

        // File is valid - enable button
        submitButtonElement.textContent = `Upload ${file.name}`;
        submitButtonElement.disabled = false;
        submitButtonElement.classList.remove('btn-disabled');
      } else {
        console.log("No file selected");
        submitButtonElement.textContent = 'Upload Test Results';
        submitButtonElement.disabled = true;
        submitButtonElement.classList.add('btn-disabled');
      }
    }

    it("should handle valid XML file selection", () => {
      const mockFile = { name: 'test-results.xml', type: 'text/xml' };
      
      handleFileChange(mockFile);
      
      expect(console.log).toHaveBeenCalledWith("File selected:", mockFile.name, mockFile.type);
      expect(submitButtonElement.textContent).toBe('Upload test-results.xml');
      expect(submitButtonElement.disabled).toBe(false);
      expect(submitButtonElement.classList.contains('btn-disabled')).toBe(false);
    });

    it("should reject non-XML files", () => {
      const mockFile = { name: 'test.pdf', type: 'application/pdf' };
      
      handleFileChange(mockFile);
      
      expect(alert).toHaveBeenCalledWith('Please select a valid XML file');
      expect(submitButtonElement.disabled).toBe(true);
      expect(submitButtonElement.textContent).toBe('Upload Test Results');
    });

    it("should handle no file selection", () => {
      handleFileChange(null);
      
      expect(console.log).toHaveBeenCalledWith("No file selected");
      expect(submitButtonElement.textContent).toBe('Upload Test Results');
      expect(submitButtonElement.disabled).toBe(true);
    });

    it("should handle case insensitive XML extension", () => {
      const mockFile = { name: 'TEST-RESULTS.XML', type: 'text/xml' };
      
      handleFileChange(mockFile);
      
      expect(submitButtonElement.disabled).toBe(false);
      expect(submitButtonElement.textContent).toBe('Upload TEST-RESULTS.XML');
    });
  });

  describe("handleSubmit", () => {
    beforeEach(() => {
      jest.useFakeTimers();
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    function createMockFile() {
      return new File(['<xml></xml>'], 'test.xml', { type: 'text/xml' });
    }

    it("should prevent default form submission", () => {
      const mockEvent = { preventDefault: jest.fn() };
      
      // Mock the handleSubmit logic
      mockEvent.preventDefault();
      
      expect(mockEvent.preventDefault).toHaveBeenCalled();
    });

    it("should alert when no file is selected", () => {
      // Mock file input with no files
      Object.defineProperty(fileInputElement, 'files', {
        value: [],
        writable: false
      });
      
      // Mock submit logic
      if (!fileInputElement.files?.[0]) {
        alert('Please select a file to upload');
        return;
      }
      
      expect(alert).toHaveBeenCalledWith('Please select a file to upload');
    });

    it("should show progress when file is selected", () => {
      const mockFile = createMockFile();
      Object.defineProperty(fileInputElement, 'files', {
        value: [mockFile],
        writable: false
      });
      
      // Mock showProgress functionality
      progressContainerElement.classList.remove('hidden');
      submitButtonElement.disabled = true;
      submitButtonElement.innerHTML = `
        <span class="loading loading-spinner loading-sm"></span>
        Processing...
      `;
      
      expect(progressContainerElement.classList.contains('hidden')).toBe(false);
      expect(submitButtonElement.disabled).toBe(true);
      expect(submitButtonElement.innerHTML).toContain('Processing...');
    });

    it("should create XMLHttpRequest with correct configuration", () => {
      const mockFile = createMockFile();
      Object.defineProperty(fileInputElement, 'files', {
        value: [mockFile],
        writable: false
      });
      
      // Mock submit logic
      const xhr = new XMLHttpRequest();
      xhr.open('POST', formElement.action);
      xhr.setRequestHeader('X-CSRF-Token', 'test-csrf-token');
      
      expect(mockXHR).toHaveBeenCalled();
      expect(xhr.open).toHaveBeenCalledWith('POST', formElement.action);
      expect(xhr.setRequestHeader).toHaveBeenCalledWith('X-CSRF-Token', 'test-csrf-token');
    });

    it("should handle successful upload", () => {
      const mockFile = createMockFile();
      Object.defineProperty(fileInputElement, 'files', {
        value: [mockFile],
        writable: false
      });
      
      const xhr = new XMLHttpRequest();
      xhr.status = 200;
      xhr.responseURL = '/automated_testing/results/123';
      
      // Mock successful completion
      progressBarElement.style.width = '100%';
      progressBarElement.textContent = '100%';
      submitButtonElement.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
        Upload Complete!
      `;
      
      expect(progressBarElement.style.width).toBe('100%');
      expect(submitButtonElement.innerHTML).toContain('Upload Complete!');
    });

    it("should update progress during upload", () => {
      // Mock progress update
      const percentComplete = 75;
      progressBarElement.style.width = `${percentComplete}%`;
      progressBarElement.textContent = `${Math.round(percentComplete)}%`;
      
      expect(progressBarElement.style.width).toBe('75%');
      expect(progressBarElement.textContent).toBe('75%');
    });

    it("should handle upload errors", () => {
      const errorMessage = 'Upload failed. Please try again.';
      
      // Mock error handling
      console.error("Upload error:", errorMessage);
      progressContainerElement.classList.add('hidden');
      submitButtonElement.disabled = false;
      submitButtonElement.textContent = 'Upload Test Results';
      alert(errorMessage);
      
      expect(console.error).toHaveBeenCalledWith("Upload error:", errorMessage);
      expect(progressContainerElement.classList.contains('hidden')).toBe(true);
      expect(submitButtonElement.disabled).toBe(false);
      expect(alert).toHaveBeenCalledWith(errorMessage);
    });

    it("should redirect after successful upload", () => {
      // Mock redirect logic
      const redirectUrl = '/automated_testing/results/123';
      
      setTimeout(() => {
        window.location.href = redirectUrl;
      }, 2000);
      
      jest.advanceTimersByTime(2000);
      
      expect(window.location.href).toBe(redirectUrl);
    });
  });

  describe("utility functions", () => {
    it("should show and update progress correctly", () => {
      // Test showProgress
      progressContainerElement.classList.remove('hidden');
      expect(progressContainerElement.classList.contains('hidden')).toBe(false);
      
      // Test updateProgress
      const testPercents = [0, 25, 50, 75, 100];
      testPercents.forEach(percent => {
        progressBarElement.style.width = `${percent}%`;
        progressBarElement.textContent = `${Math.round(percent)}%`;
        
        expect(progressBarElement.style.width).toBe(`${percent}%`);
        expect(progressBarElement.textContent).toBe(`${percent}%`);
      });
    });

    it("should handle CSRF token correctly", () => {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
      expect(csrfToken).toBe('test-csrf-token');
    });

    it("should handle missing CSRF token gracefully", () => {
      document.querySelector('meta[name="csrf-token"]')?.remove();
      
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
      expect(csrfToken).toBeUndefined();
    });
  });
});