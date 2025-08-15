/**
 * @jest-environment jsdom
 */

import UploadController from "../controllers/upload_controller"

describe("UploadController", () => {
  let controller;
  let mockElement;
  let mockFormTarget;
  let mockFileInputTarget;
  let mockSubmitButtonTarget;
  let mockProgressBarTarget;
  let mockProgressContainerTarget;
  let mockXHR;
  let xhrInstances;

  beforeEach(() => {
    mockElement = document.createElement('div');
    mockFormTarget = document.createElement('form');
    mockFormTarget.action = '/test-upload';
    
    mockFileInputTarget = document.createElement('input');
    mockFileInputTarget.type = 'file';
    
    mockSubmitButtonTarget = document.createElement('button');
    mockSubmitButtonTarget.textContent = 'Upload Test Results';
    
    mockProgressBarTarget = document.createElement('div');
    mockProgressBarTarget.style.width = '0%';
    
    mockProgressContainerTarget = document.createElement('div');
    mockProgressContainerTarget.classList.add('hidden');
    
    document.body.appendChild(mockElement);
    document.body.appendChild(mockFormTarget);
    document.body.appendChild(mockFileInputTarget);
    document.body.appendChild(mockSubmitButtonTarget);
    document.body.appendChild(mockProgressBarTarget);
    document.body.appendChild(mockProgressContainerTarget);

    // Add CSRF token meta tag
    const csrfMeta = document.createElement('meta');
    csrfMeta.name = 'csrf-token';
    csrfMeta.content = 'test-csrf-token';
    document.head.appendChild(csrfMeta);

    // Mock console.error to prevent test noise
    jest.spyOn(console, 'error').mockImplementation(() => {});

    controller = new UploadController();
    
    // Mock the element and targets
    Object.defineProperty(controller, 'element', {
      value: mockElement,
      writable: false,
      configurable: true
    });
    
    Object.defineProperty(controller, 'formTarget', {
      value: mockFormTarget,
      writable: false,
      configurable: true
    });
    
    Object.defineProperty(controller, 'fileInputTarget', {
      value: mockFileInputTarget,
      writable: false,
      configurable: true
    });
    
    Object.defineProperty(controller, 'submitButtonTarget', {
      value: mockSubmitButtonTarget,
      writable: false,
      configurable: true
    });
    
    Object.defineProperty(controller, 'progressBarTarget', {
      value: mockProgressBarTarget,
      writable: false,
      configurable: true
    });
    
    Object.defineProperty(controller, 'progressContainerTarget', {
      value: mockProgressContainerTarget,
      writable: false,
      configurable: true
    });

    // Mock XMLHttpRequest
    xhrInstances = [];
    mockXHR = jest.fn(() => {
      const xhr = {
        open: jest.fn(),
        send: jest.fn(),
        setRequestHeader: jest.fn(),
        addEventListener: jest.fn(),
        upload: {
          addEventListener: jest.fn()
        },
        status: 200,
        responseURL: ''
      };
      xhrInstances.push(xhr);
      return xhr;
    });
    global.XMLHttpRequest = mockXHR;

    // Mock alert, console.log, and window.location.href
    global.alert = jest.fn();
    global.console.log = jest.fn();
    
    Object.defineProperty(window, 'location', {
      value: { href: '' },
      writable: true
    });
  });

  afterEach(() => {
    document.head.innerHTML = '';
    document.body.innerHTML = '';
    jest.clearAllMocks();
  });

  describe("connect behavior", () => {
    it("should log connection and set up event listeners", () => {
      const consoleLogSpy = jest.spyOn(console, 'log');
      const addEventListenerSpy = jest.spyOn(mockFormTarget, 'addEventListener');
      const inputAddEventListenerSpy = jest.spyOn(mockFileInputTarget, 'addEventListener');
      
      controller.connect();
      
      expect(consoleLogSpy).toHaveBeenCalledWith("Upload controller connected");
      expect(addEventListenerSpy).toHaveBeenCalledWith('submit', expect.any(Function));
      expect(inputAddEventListenerSpy).toHaveBeenCalledWith('change', expect.any(Function));
    });

    it("should disable submit button initially", () => {
      controller.connect();
      
      expect(mockSubmitButtonTarget.disabled).toBe(true);
    });
  });

  describe("handleFileChange", () => {
    beforeEach(() => {
      controller.connect();
    });

    it("should handle valid XML file selection", () => {
      const mockFile = {
        name: 'test-results.xml',
        type: 'application/xml'
      };
      
      const mockEvent = {
        target: {
          files: [mockFile]
        }
      };
      
      const consoleLogSpy = jest.spyOn(console, 'log');
      
      controller.handleFileChange(mockEvent);
      
      expect(consoleLogSpy).toHaveBeenCalledWith("File change event triggered");
      expect(consoleLogSpy).toHaveBeenCalledWith("File selected:", mockFile.name, mockFile.type);
      expect(consoleLogSpy).toHaveBeenCalledWith("Button enabled for file:", mockFile.name);
      
      expect(mockSubmitButtonTarget.textContent).toBe(`Upload ${mockFile.name}`);
      expect(mockSubmitButtonTarget.disabled).toBe(false);
      expect(mockSubmitButtonTarget.classList.contains('btn-disabled')).toBe(false);
    });

    it("should reject non-XML files", () => {
      const mockFile = {
        name: 'test-results.txt',
        type: 'text/plain'
      };
      
      const mockEvent = {
        target: {
          files: [mockFile],
          value: 'fake-value'
        }
      };
      
      controller.handleFileChange(mockEvent);
      
      expect(global.alert).toHaveBeenCalledWith('Please select a valid XML file');
      expect(mockEvent.target.value).toBe('');
      expect(mockSubmitButtonTarget.disabled).toBe(true);
      expect(mockSubmitButtonTarget.textContent).toBe('Upload Test Results');
    });

    it("should handle no file selection", () => {
      const mockEvent = {
        target: {
          files: []
        }
      };
      
      const consoleLogSpy = jest.spyOn(console, 'log');
      
      controller.handleFileChange(mockEvent);
      
      expect(consoleLogSpy).toHaveBeenCalledWith("No file selected");
      expect(mockSubmitButtonTarget.textContent).toBe('Upload Test Results');
      expect(mockSubmitButtonTarget.disabled).toBe(true);
      expect(mockSubmitButtonTarget.classList.contains('btn-disabled')).toBe(true);
    });

    it("should handle null files array", () => {
      const mockEvent = {
        target: {
          files: null
        }
      };
      
      expect(() => {
        controller.handleFileChange(mockEvent);
      }).not.toThrow();
    });

    it("should handle empty files array", () => {
      const mockEvent = {
        target: {
          files: []
        }
      };
      
      controller.handleFileChange(mockEvent);
      
      expect(mockSubmitButtonTarget.disabled).toBe(true);
    });

    it("should validate XML file extension case-insensitively", () => {
      const mockFile = {
        name: 'test-results.XML',
        type: 'application/xml'
      };
      
      const mockEvent = {
        target: {
          files: [mockFile]
        }
      };
      
      controller.handleFileChange(mockEvent);
      
      expect(mockSubmitButtonTarget.disabled).toBe(false);
      expect(mockSubmitButtonTarget.textContent).toBe(`Upload ${mockFile.name}`);
    });
  });

  describe("handleSubmit", () => {
    beforeEach(() => {
      controller.connect();
    });

    it("should prevent default and show alert when no file selected", () => {
      const mockEvent = {
        preventDefault: jest.fn()
      };
      
      Object.defineProperty(mockFileInputTarget, 'files', {
        value: null,
        configurable: true
      });
      
      controller.handleSubmit(mockEvent);
      
      expect(mockEvent.preventDefault).toHaveBeenCalled();
      expect(global.alert).toHaveBeenCalledWith('Please select a file to upload');
    });

    it("should handle successful upload with default redirect", () => {
      const mockFile = new File(['content'], 'test.xml', { type: 'application/xml' });
      const mockEvent = {
        preventDefault: jest.fn()
      };
      
      // Mock the files property properly
      Object.defineProperty(mockFileInputTarget, 'files', {
        value: [mockFile],
        configurable: true
      });
      
      const consoleLogSpy = jest.spyOn(console, 'log');
      
      controller.handleSubmit(mockEvent);
      
      expect(mockEvent.preventDefault).toHaveBeenCalled();
      expect(consoleLogSpy).toHaveBeenCalledWith("Form submit triggered");
      expect(consoleLogSpy).toHaveBeenCalledWith("Sending upload request...");
      
      const xhr = xhrInstances[0];
      expect(xhr.open).toHaveBeenCalledWith('POST', 'http://localhost/test-upload');
      expect(xhr.setRequestHeader).toHaveBeenCalledWith('X-CSRF-Token', 'test-csrf-token');
    });

    it("should handle upload progress updates", () => {
      const mockFile = new File(['content'], 'test.xml', { type: 'application/xml' });
      const mockEvent = {
        preventDefault: jest.fn()
      };
      
      Object.defineProperty(mockFileInputTarget, "files", { value: [mockFile], configurable: true });
      
      controller.handleSubmit(mockEvent);
      
      const xhr = xhrInstances[0];
      const progressCallback = xhr.upload.addEventListener.mock.calls[0][1];
      
      // Simulate progress event
      const progressEvent = {
        lengthComputable: true,
        loaded: 500,
        total: 1000
      };
      
      progressCallback(progressEvent);
      
      expect(mockProgressBarTarget.style.width).toBe('50%');
      expect(mockProgressBarTarget.textContent).toBe('50%');
    });

    it("should handle successful upload completion", () => {
      const mockFile = new File(['content'], 'test.xml', { type: 'application/xml' });
      const mockEvent = {
        preventDefault: jest.fn()
      };
      
      Object.defineProperty(mockFileInputTarget, "files", { value: [mockFile], configurable: true });
      
      // Mock setTimeout
      jest.useFakeTimers();
      
      controller.handleSubmit(mockEvent);
      
      const xhr = xhrInstances[0];
      xhr.status = 200;
      
      const loadCallback = xhr.addEventListener.mock.calls.find(call => call[0] === 'load')[1];
      loadCallback();
      
      expect(mockProgressBarTarget.style.width).toBe('100%');
      expect(mockProgressBarTarget.textContent).toBe('100%');
      expect(mockSubmitButtonTarget.textContent).toContain('Upload Complete!');
      
      jest.advanceTimersByTime(2000);
      expect(window.location.href).toBe('/automated_testing/results');
      
      jest.useRealTimers();
    });

    it("should handle upload with custom redirect URL", () => {
      const mockFile = new File(['content'], 'test.xml', { type: 'application/xml' });
      const mockEvent = {
        preventDefault: jest.fn()
      };
      
      Object.defineProperty(mockFileInputTarget, "files", { value: [mockFile], configurable: true });
      
      jest.useFakeTimers();
      
      controller.handleSubmit(mockEvent);
      
      const xhr = xhrInstances[0];
      xhr.status = 302;
      xhr.responseURL = 'https://example.com/automated_testing/results/123';
      
      const loadCallback = xhr.addEventListener.mock.calls.find(call => call[0] === 'load')[1];
      loadCallback();
      
      jest.advanceTimersByTime(2000);
      expect(window.location.href).toBe('https://example.com/automated_testing/results/123');
      
      jest.useRealTimers();
    });

    it("should handle upload error", () => {
      // Reset the mock to track calls for this specific test
      console.error.mockClear();
      
      const mockFile = new File(['content'], 'test.xml', { type: 'application/xml' });
      const mockEvent = {
        preventDefault: jest.fn()
      };
      
      Object.defineProperty(mockFileInputTarget, "files", { value: [mockFile], configurable: true });
      
      controller.handleSubmit(mockEvent);
      
      const xhr = xhrInstances[0];
      xhr.status = 500;
      
      const loadCallback = xhr.addEventListener.mock.calls.find(call => call[0] === 'load')[1];
      loadCallback();
      
      expect(console.error).toHaveBeenCalledWith("Upload failed with status:", 500);
      expect(console.error).toHaveBeenCalledWith("Upload error:", "Upload failed. Please try again.");
      expect(mockSubmitButtonTarget.textContent).toBe('Upload Test Results');
    });

    it("should handle network error", () => {
      // Reset the mock to track calls for this specific test
      console.error.mockClear();
      
      const mockFile = new File(['content'], 'test.xml', { type: 'application/xml' });
      const mockEvent = {
        preventDefault: jest.fn()
      };
      
      Object.defineProperty(mockFileInputTarget, "files", { value: [mockFile], configurable: true });
      
      controller.handleSubmit(mockEvent);
      
      const xhr = xhrInstances[0];
      
      const errorCallback = xhr.addEventListener.mock.calls.find(call => call[0] === 'error')[1];
      errorCallback();
      
      expect(console.error).toHaveBeenCalledWith("Upload error occurred");
      expect(console.error).toHaveBeenCalledWith("Upload error:", "Upload failed. Please check your connection and try again.");
      expect(mockSubmitButtonTarget.textContent).toBe('Upload Test Results');
    });
  });

  describe("showProgress", () => {
    it("should show progress container and update button", () => {
      controller.showProgress();
      
      expect(mockProgressContainerTarget.classList.contains('hidden')).toBe(false);
      expect(mockSubmitButtonTarget.disabled).toBe(true);
      expect(mockSubmitButtonTarget.innerHTML).toContain('loading loading-spinner');
      expect(mockSubmitButtonTarget.innerHTML).toContain('Processing...');
    });
  });

  describe("updateProgress", () => {
    it("should update progress bar with percentage", () => {
      controller.updateProgress(75);
      
      expect(mockProgressBarTarget.style.width).toBe('75%');
      expect(mockProgressBarTarget.textContent).toBe('75%');
    });

    it("should round percentage values", () => {
      controller.updateProgress(33.333);
      
      expect(mockProgressBarTarget.textContent).toBe('33%');
    });
  });

  describe("showSuccess", () => {
    it("should display success state", () => {
      controller.showSuccess();
      
      expect(mockProgressBarTarget.style.width).toBe('100%');
      expect(mockProgressBarTarget.textContent).toBe('100%');
      expect(mockSubmitButtonTarget.innerHTML).toContain('Upload Complete!');
      expect(mockSubmitButtonTarget.classList.contains('btn-success')).toBe(true);
      expect(mockSubmitButtonTarget.classList.contains('btn-primary')).toBe(false);
    });
  });

  describe("showError", () => {
    it("should display error state and show alert", () => {
      // Reset the mock to track calls for this specific test
      console.error.mockClear();
      
      const testMessage = "Test error message";
      
      controller.showError(testMessage);
      
      expect(console.error).toHaveBeenCalledWith("Upload error:", testMessage);
      expect(mockProgressContainerTarget.classList.contains('hidden')).toBe(true);
      expect(mockSubmitButtonTarget.disabled).toBe(false);
      expect(mockSubmitButtonTarget.textContent).toBe('Upload Test Results');
      expect(mockSubmitButtonTarget.classList.contains('btn-primary')).toBe(true);
      expect(mockSubmitButtonTarget.classList.contains('btn-success')).toBe(false);
      expect(global.alert).toHaveBeenCalledWith(testMessage);
    });
  });

  describe("integration scenarios", () => {
    beforeEach(() => {
      controller.connect();
    });

    it("should handle complete upload workflow", () => {
      // File selection
      const mockFile = {
        name: 'test-results.xml',
        type: 'application/xml'
      };
      
      const fileChangeEvent = {
        target: {
          files: [mockFile]
        }
      };
      
      controller.handleFileChange(fileChangeEvent);
      expect(mockSubmitButtonTarget.disabled).toBe(false);
      
      // File submission
      Object.defineProperty(mockFileInputTarget, 'files', {
        value: [new File(['content'], 'test.xml', { type: 'application/xml' })],
        configurable: true
      });
      
      const submitEvent = {
        preventDefault: jest.fn()
      };
      
      jest.useFakeTimers();
      
      controller.handleSubmit(submitEvent);
      
      // Simulate successful upload
      const xhr = xhrInstances[0];
      xhr.status = 200;
      
      const loadCallback = xhr.addEventListener.mock.calls.find(call => call[0] === 'load')[1];
      loadCallback();
      
      expect(mockSubmitButtonTarget.innerHTML).toContain('Upload Complete!');
      
      jest.advanceTimersByTime(2000);
      expect(window.location.href).toBe('/automated_testing/results');
      
      jest.useRealTimers();
    });

    it("should handle error recovery", () => {
      // Start with error state
      controller.showError("Test error");
      expect(mockSubmitButtonTarget.disabled).toBe(false);
      expect(global.alert).toHaveBeenCalled();
      
      // Then show success
      controller.showSuccess();
      expect(mockSubmitButtonTarget.classList.contains('btn-success')).toBe(true);
    });

    it("should handle 422 validation errors correctly", () => {
      controller.connect();
      
      // Set up file for upload
      Object.defineProperty(mockFileInputTarget, 'files', {
        value: [new File(['content'], 'test.xml', { type: 'application/xml' })],
        configurable: true
      });
      
      const submitEvent = {
        preventDefault: jest.fn()
      };
      
      controller.handleSubmit(submitEvent);
      
      // Simulate 422 validation error
      const xhr = xhrInstances[0];
      xhr.status = 422;
      xhr.responseText = 'Validation errors: must be an XML file';
      
      const loadCallback = xhr.addEventListener.mock.calls.find(call => call[0] === 'load')[1];
      loadCallback();
      
      expect(global.alert).toHaveBeenCalledWith('Please upload a valid XML file.');
    });

    it("should handle 422 file size errors correctly", () => {
      controller.connect();
      
      Object.defineProperty(mockFileInputTarget, 'files', {
        value: [new File(['content'], 'test.xml', { type: 'application/xml' })],
        configurable: true
      });
      
      const submitEvent = {
        preventDefault: jest.fn()
      };
      
      controller.handleSubmit(submitEvent);
      
      // Simulate 422 file size error
      const xhr = xhrInstances[0];
      xhr.status = 422;
      xhr.responseText = 'Validation errors: must be less than 50MB';
      
      const loadCallback = xhr.addEventListener.mock.calls.find(call => call[0] === 'load')[1];
      loadCallback();
      
      expect(global.alert).toHaveBeenCalledWith('File size must be less than 50MB.');
    });

    it("should handle generic 422 validation errors", () => {
      controller.connect();
      
      Object.defineProperty(mockFileInputTarget, 'files', {
        value: [new File(['content'], 'test.xml', { type: 'application/xml' })],
        configurable: true
      });
      
      const submitEvent = {
        preventDefault: jest.fn()
      };
      
      controller.handleSubmit(submitEvent);
      
      // Simulate generic 422 error
      const xhr = xhrInstances[0];
      xhr.status = 422;
      xhr.responseText = 'Some other validation error';
      
      const loadCallback = xhr.addEventListener.mock.calls.find(call => call[0] === 'load')[1];
      loadCallback();
      
      expect(global.alert).toHaveBeenCalledWith('Upload failed due to validation errors. Please check your file and try again.');
    });

    it("should validate XML file extension", () => {
      controller.connect();
      
      const mockFile = {
        name: 'test-results.txt', // Invalid extension
        type: 'text/plain'
      };
      
      const fileChangeEvent = {
        target: {
          files: [mockFile],
          value: 'test-results.txt'
        }
      };
      
      controller.handleFileChange(fileChangeEvent);
      
      expect(global.alert).toHaveBeenCalledWith('Please select a valid XML file');
      expect(fileChangeEvent.target.value).toBe('');
      expect(mockSubmitButtonTarget.disabled).toBe(true);
    });
  });

  describe("edge cases", () => {
    beforeEach(() => {
      controller.connect();
    });

    it("should handle missing CSRF token", () => {
      document.head.innerHTML = ''; // Remove CSRF token
      
      const mockFile = new File(['content'], 'test.xml', { type: 'application/xml' });
      const mockEvent = {
        preventDefault: jest.fn()
      };
      
      Object.defineProperty(mockFileInputTarget, "files", { value: [mockFile], configurable: true });
      
      expect(() => {
        controller.handleSubmit(mockEvent);
      }).not.toThrow();
      
      const xhr = xhrInstances[0];
      expect(xhr.setRequestHeader).not.toHaveBeenCalledWith('X-CSRF-Token', expect.any(String));
    });

    it("should handle progress event without lengthComputable", () => {
      const mockFile = new File(['content'], 'test.xml', { type: 'application/xml' });
      const mockEvent = {
        preventDefault: jest.fn()
      };
      
      Object.defineProperty(mockFileInputTarget, "files", { value: [mockFile], configurable: true });
      
      controller.handleSubmit(mockEvent);
      
      const xhr = xhrInstances[0];
      const progressCallback = xhr.upload.addEventListener.mock.calls[0][1];
      
      const progressEvent = {
        lengthComputable: false,
        loaded: 500,
        total: 1000
      };
      
      expect(() => {
        progressCallback(progressEvent);
      }).not.toThrow();
    });

    it("should handle invalid responseURL in success handler", () => {
      const mockFile = new File(['content'], 'test.xml', { type: 'application/xml' });
      const mockEvent = {
        preventDefault: jest.fn()
      };
      
      Object.defineProperty(mockFileInputTarget, "files", { value: [mockFile], configurable: true });
      
      jest.useFakeTimers();
      
      controller.handleSubmit(mockEvent);
      
      const xhr = xhrInstances[0];
      xhr.status = 200;
      xhr.responseURL = 'invalid-url';
      
      const loadCallback = xhr.addEventListener.mock.calls.find(call => call[0] === 'load')[1];
      loadCallback();
      
      // Should use default URL since responseURL doesn't contain 'automated_testing/results'
      jest.advanceTimersByTime(2000);
      expect(window.location.href).toBe('/automated_testing/results');
      
      jest.useRealTimers();
    });

    it("should handle files with mixed case extensions", () => {
      const extensions = ['.xml', '.XML', '.xMl', '.Xml'];
      
      extensions.forEach(ext => {
        const mockFile = {
          name: `test${ext}`,
          type: 'application/xml'
        };
        
        const mockEvent = {
          target: {
            files: [mockFile]
          }
        };
        
        controller.handleFileChange(mockEvent);
        expect(mockSubmitButtonTarget.disabled).toBe(false);
      });
    });

    it("should handle responseURL parsing error in success handler", () => {
      jest.useFakeTimers();
      
      const mockFile = new File(['content'], 'test.xml', { type: 'application/xml' });
      const mockEvent = {
        preventDefault: jest.fn()
      };
      
      Object.defineProperty(mockFileInputTarget, "files", { value: [mockFile], configurable: true });
      
      controller.handleSubmit(mockEvent);
      
      const xhr = xhrInstances[0];
      xhr.status = 200;
      
      // Mock xhr.responseURL to throw an error when accessed
      Object.defineProperty(xhr, 'responseURL', {
        get() {
          throw new Error('ResponseURL access error');
        }
      });
      
      const loadCallback = xhr.addEventListener.mock.calls.find(call => call[0] === 'load')[1];
      loadCallback();
      
      // Fast-forward time to trigger the redirect
      jest.advanceTimersByTime(2000);
      
      // Should fall back to default redirect URL
      expect(window.location.href).toBe('/automated_testing/results');
      
      jest.useRealTimers();
    });

    it("should handle JSON parsing error in 422 validation response", () => {
      const mockFile = new File(['content'], 'test.xml', { type: 'application/xml' });
      const mockEvent = {
        preventDefault: jest.fn()
      };
      
      Object.defineProperty(mockFileInputTarget, "files", { value: [mockFile], configurable: true });
      
      controller.handleSubmit(mockEvent);
      
      const xhr = xhrInstances[0];
      xhr.status = 422;
      
      // Mock xhr.responseText to throw an error when accessed
      Object.defineProperty(xhr, 'responseText', {
        get() {
          throw new Error('ResponseText access error');
        }
      });
      
      const loadCallback = xhr.addEventListener.mock.calls.find(call => call[0] === 'load')[1];
      loadCallback();
      
      // Should fall back to generic validation error message
      expect(global.alert).toHaveBeenCalledWith('Upload failed due to validation errors. Please check your file and try again.');
    });
  });
});