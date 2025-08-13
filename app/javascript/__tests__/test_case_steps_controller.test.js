/**
 * @jest-environment jsdom
 */

import TestCaseStepsController from "../controllers/test_case_steps_controller"

describe("TestCaseStepsController", () => {
  let controller;
  let mockElement;
  let mockStepsContainer;
  let mockStepInput;
  let mockStepsList;
  let mockHiddenInput;

  beforeEach(() => {
    mockElement = document.createElement('div');
    mockStepsContainer = document.createElement('div');
    mockStepInput = document.createElement('input');
    mockStepInput.type = 'text';
    mockStepsList = document.createElement('div');
    mockHiddenInput = document.createElement('input');
    mockHiddenInput.type = 'hidden';
    
    document.body.appendChild(mockElement);
    document.body.appendChild(mockStepsContainer);
    document.body.appendChild(mockStepInput);
    document.body.appendChild(mockStepsList);
    document.body.appendChild(mockHiddenInput);
    
    controller = new TestCaseStepsController();
    
    // Mock the element and targets
    Object.defineProperty(controller, 'element', {
      value: mockElement,
      writable: false,
      configurable: true
    });
    
    Object.defineProperty(controller, 'stepsContainerTarget', {
      value: mockStepsContainer,
      writable: false,
      configurable: true
    });
    
    Object.defineProperty(controller, 'stepInputTarget', {
      value: mockStepInput,
      writable: false,
      configurable: true
    });
    
    Object.defineProperty(controller, 'stepsListTarget', {
      value: mockStepsList,
      writable: false,
      configurable: true
    });
    
    Object.defineProperty(controller, 'hiddenInputTarget', {
      value: mockHiddenInput,
      writable: false,
      configurable: true
    });

    // Mock focus method
    mockStepInput.focus = jest.fn();
  });

  afterEach(() => {
    document.body.innerHTML = '';
    jest.clearAllMocks();
  });

  describe("connect behavior", () => {
    it("should initialize with empty steps array", () => {
      controller.connect();
      
      expect(controller.steps).toEqual([]);
      expect(mockHiddenInput.value).toBe('[]');
    });
  });

  describe("addStep method", () => {
    beforeEach(() => {
      controller.connect();
    });

    it("should add step on Enter key press", () => {
      mockStepInput.value = "Test step 1";
      const mockEvent = { 
        key: "Enter", 
        preventDefault: jest.fn() 
      };
      
      controller.addStep(mockEvent);
      
      expect(mockEvent.preventDefault).toHaveBeenCalled();
      expect(controller.steps).toEqual(["Test step 1"]);
    });

    it("should not add step on other key presses", () => {
      mockStepInput.value = "Test step 1";
      const mockEvent = { 
        key: "Space", 
        preventDefault: jest.fn() 
      };
      
      controller.addStep(mockEvent);
      
      expect(mockEvent.preventDefault).not.toHaveBeenCalled();
      expect(controller.steps).toEqual([]);
    });

    it("should handle multiple key presses", () => {
      const keys = ["Tab", "Shift", "Control", "Alt", "Escape"];
      
      keys.forEach(key => {
        mockStepInput.value = `Test for ${key}`;
        const mockEvent = { 
          key: key, 
          preventDefault: jest.fn() 
        };
        
        controller.addStep(mockEvent);
        expect(mockEvent.preventDefault).not.toHaveBeenCalled();
      });
      
      expect(controller.steps).toEqual([]);
    });
  });

  describe("createStep method", () => {
    beforeEach(() => {
      controller.connect();
    });

    it("should add step with trimmed text", () => {
      mockStepInput.value = "  Test step with spaces  ";
      
      controller.createStep();
      
      expect(controller.steps).toEqual(["Test step with spaces"]);
      expect(mockStepInput.value).toBe("");
    });

    it("should not add empty or whitespace-only steps", () => {
      mockStepInput.value = "   ";
      
      controller.createStep();
      
      expect(controller.steps).toEqual([]);
      expect(mockStepInput.value).toBe("   "); // Should not clear if invalid
    });

    it("should not add empty string", () => {
      mockStepInput.value = "";
      
      controller.createStep();
      
      expect(controller.steps).toEqual([]);
    });

    it("should clear input and focus after adding valid step", () => {
      mockStepInput.value = "Valid step";
      
      controller.createStep();
      
      expect(mockStepInput.value).toBe("");
      expect(mockStepInput.focus).toHaveBeenCalled();
    });

    it("should update hidden input after adding step", () => {
      mockStepInput.value = "Test step 1";
      controller.createStep();
      
      mockStepInput.value = "Test step 2";
      controller.createStep();
      
      expect(mockHiddenInput.value).toBe('["Test step 1","Test step 2"]');
    });
  });

  describe("removeStep method", () => {
    beforeEach(() => {
      controller.connect();
      // Pre-populate with test steps
      controller.steps = ["Step 1", "Step 2", "Step 3"];
      controller.renderSteps();
      controller.updateHiddenInput();
    });

    it("should remove step at specified index", () => {
      const mockEvent = { 
        target: { 
          dataset: { index: "1" } 
        } 
      };
      
      controller.removeStep(mockEvent);
      
      expect(controller.steps).toEqual(["Step 1", "Step 3"]);
      expect(mockHiddenInput.value).toBe('["Step 1","Step 3"]');
    });

    it("should remove first step", () => {
      const mockEvent = { 
        target: { 
          dataset: { index: "0" } 
        } 
      };
      
      controller.removeStep(mockEvent);
      
      expect(controller.steps).toEqual(["Step 2", "Step 3"]);
    });

    it("should remove last step", () => {
      const mockEvent = { 
        target: { 
          dataset: { index: "2" } 
        } 
      };
      
      controller.removeStep(mockEvent);
      
      expect(controller.steps).toEqual(["Step 1", "Step 2"]);
    });

    it("should handle string index conversion", () => {
      const mockEvent = { 
        target: { 
          dataset: { index: "1" } 
        } 
      };
      
      controller.removeStep(mockEvent);
      
      expect(controller.steps.length).toBe(2);
      expect(controller.steps).not.toContain("Step 2");
    });
  });

  describe("renderSteps method", () => {
    beforeEach(() => {
      controller.connect();
    });

    it("should render empty list when no steps", () => {
      controller.steps = [];
      controller.renderSteps();
      
      expect(mockStepsList.children.length).toBe(0);
      expect(mockStepsList.innerHTML).toBe("");
    });

    it("should render all steps with correct numbering", () => {
      controller.steps = ["First step", "Second step", "Third step"];
      controller.renderSteps();
      
      expect(mockStepsList.children.length).toBe(3);
      
      const stepNumbers = mockStepsList.querySelectorAll('.w-8.h-8');
      expect(stepNumbers[0].textContent.trim()).toBe('1');
      expect(stepNumbers[1].textContent.trim()).toBe('2');
      expect(stepNumbers[2].textContent.trim()).toBe('3');
    });

    it("should render step content correctly", () => {
      controller.steps = ["Test step content"];
      controller.renderSteps();
      
      const content = mockStepsList.querySelector('p');
      expect(content.textContent).toBe("Test step content");
    });

    it("should add remove buttons with correct indices", () => {
      controller.steps = ["Step 1", "Step 2"];
      controller.renderSteps();
      
      const buttons = mockStepsList.querySelectorAll('button');
      expect(buttons[0].getAttribute('data-index')).toBe('0');
      expect(buttons[1].getAttribute('data-index')).toBe('1');
    });

    it("should escape HTML in step content", () => {
      controller.steps = ["<script>alert('xss')</script>"];
      controller.renderSteps();
      
      const content = mockStepsList.querySelector('p');
      // The escapeHtml method should prevent XSS
      expect(content.textContent).toBe("<script>alert('xss')</script>");
      expect(content.innerHTML).toContain("&lt;script&gt;");
    });

    it("should add proper CSS classes", () => {
      controller.steps = ["Test step"];
      controller.renderSteps();
      
      const stepElement = mockStepsList.firstChild;
      expect(stepElement.className).toContain("flex");
      expect(stepElement.className).toContain("items-start");
      expect(stepElement.className).toContain("gap-3");
    });
  });

  describe("updateHiddenInput method", () => {
    beforeEach(() => {
      controller.connect();
    });

    it("should serialize empty array", () => {
      controller.steps = [];
      controller.updateHiddenInput();
      
      expect(mockHiddenInput.value).toBe('[]');
    });

    it("should serialize single step", () => {
      controller.steps = ["Single step"];
      controller.updateHiddenInput();
      
      expect(mockHiddenInput.value).toBe('["Single step"]');
    });

    it("should serialize multiple steps", () => {
      controller.steps = ["Step 1", "Step 2", "Step 3"];
      controller.updateHiddenInput();
      
      expect(mockHiddenInput.value).toBe('["Step 1","Step 2","Step 3"]');
    });

    it("should handle special characters in steps", () => {
      controller.steps = ["Step with \"quotes\"", "Step with 'apostrophes'", "Step with \n newlines"];
      controller.updateHiddenInput();
      
      const parsed = JSON.parse(mockHiddenInput.value);
      expect(parsed).toEqual(controller.steps);
    });
  });

  describe("escapeHtml method", () => {
    beforeEach(() => {
      controller.connect();
    });

    it("should escape HTML tags", () => {
      const result = controller.escapeHtml("<div>test</div>");
      expect(result).toBe("&lt;div&gt;test&lt;/div&gt;");
    });

    it("should escape script tags", () => {
      const result = controller.escapeHtml("<script>alert('xss')</script>");
      expect(result).toBe("&lt;script&gt;alert('xss')&lt;/script&gt;");
    });

    it("should handle ampersands", () => {
      const result = controller.escapeHtml("Tom & Jerry");
      expect(result).toBe("Tom &amp; Jerry");
    });

    it("should handle empty string", () => {
      const result = controller.escapeHtml("");
      expect(result).toBe("");
    });

    it("should handle quotes correctly", () => {
      const result = controller.escapeHtml('Text with "quotes" and \'apostrophes\'');
      expect(result).toBe('Text with "quotes" and \'apostrophes\'');
    });

    it("should handle complex HTML", () => {
      const input = '<img src="x" onerror="alert(1)">';
      const result = controller.escapeHtml(input);
      expect(result).toBe('&lt;img src="x" onerror="alert(1)"&gt;');
    });
  });

  describe("integration scenarios", () => {
    beforeEach(() => {
      controller.connect();
    });

    it("should handle complete workflow: add, remove, add", () => {
      // Add steps
      mockStepInput.value = "Step 1";
      controller.createStep();
      mockStepInput.value = "Step 2";
      controller.createStep();
      mockStepInput.value = "Step 3";
      controller.createStep();
      
      expect(controller.steps).toEqual(["Step 1", "Step 2", "Step 3"]);
      expect(mockHiddenInput.value).toBe('["Step 1","Step 2","Step 3"]');
      
      // Remove middle step
      const removeEvent = { 
        target: { 
          dataset: { index: "1" } 
        } 
      };
      controller.removeStep(removeEvent);
      
      expect(controller.steps).toEqual(["Step 1", "Step 3"]);
      expect(mockHiddenInput.value).toBe('["Step 1","Step 3"]');
      
      // Add another step
      mockStepInput.value = "Step 4";
      controller.createStep();
      
      expect(controller.steps).toEqual(["Step 1", "Step 3", "Step 4"]);
      expect(mockHiddenInput.value).toBe('["Step 1","Step 3","Step 4"]');
    });

    it("should maintain state consistency during multiple operations", () => {
      const testSteps = ["A", "B", "C", "D", "E"];
      
      // Add all steps
      testSteps.forEach(step => {
        mockStepInput.value = step;
        controller.createStep();
      });
      
      expect(controller.steps).toEqual(testSteps);
      
      // Remove specific steps
      controller.removeStep({ target: { dataset: { index: "4" } } }); // E
      controller.removeStep({ target: { dataset: { index: "2" } } }); // C
      controller.removeStep({ target: { dataset: { index: "0" } } }); // A
      
      expect(controller.steps).toEqual(["B", "D"]);
      expect(JSON.parse(mockHiddenInput.value)).toEqual(["B", "D"]);
    });

    it("should handle Enter key workflow", () => {
      mockStepInput.value = "Test via Enter";
      const enterEvent = { 
        key: "Enter", 
        preventDefault: jest.fn() 
      };
      
      controller.addStep(enterEvent);
      
      expect(enterEvent.preventDefault).toHaveBeenCalled();
      expect(controller.steps).toEqual(["Test via Enter"]);
      expect(mockStepInput.value).toBe("");
      expect(mockStepInput.focus).toHaveBeenCalled();
    });

    it("should handle rendering after multiple changes", () => {
      // Add steps
      controller.steps = ["First", "Second", "Third"];
      controller.renderSteps();
      
      expect(mockStepsList.children.length).toBe(3);
      
      // Remove one
      controller.removeStep({ target: { dataset: { index: "1" } } });
      
      expect(mockStepsList.children.length).toBe(2);
      
      // Verify numbering is correct
      const numbers = mockStepsList.querySelectorAll('.w-8.h-8');
      expect(numbers[0].textContent.trim()).toBe('1');
      expect(numbers[1].textContent.trim()).toBe('2');
    });
  });

  describe("edge cases", () => {
    beforeEach(() => {
      controller.connect();
    });

    it("should handle removing from empty array", () => {
      controller.steps = [];
      const removeEvent = { 
        target: { 
          dataset: { index: "0" } 
        } 
      };
      
      expect(() => {
        controller.removeStep(removeEvent);
      }).not.toThrow();
      
      expect(controller.steps).toEqual([]);
    });

    it("should handle invalid remove indices", () => {
      controller.steps = ["Single step"];
      const removeEvent = { 
        target: { 
          dataset: { index: "5" } 
        } 
      };
      
      expect(() => {
        controller.removeStep(removeEvent);
      }).not.toThrow();
      
      // Array should remain unchanged since index is invalid (out of bounds)
      expect(controller.steps).toEqual(["Single step"]);
    });

    it("should handle negative remove indices", () => {
      controller.steps = ["Step 1", "Step 2"];
      const removeEvent = { 
        target: { 
          dataset: { index: "-1" } 
        } 
      };
      
      expect(() => {
        controller.removeStep(removeEvent);
      }).not.toThrow();
      
      expect(controller.steps.length).toBeLessThanOrEqual(2);
    });

    it("should handle very long step content", () => {
      const longStep = "A".repeat(10000);
      mockStepInput.value = longStep;
      
      controller.createStep();
      
      expect(controller.steps).toEqual([longStep]);
      expect(JSON.parse(mockHiddenInput.value)).toEqual([longStep]);
    });

    it("should handle special unicode characters", () => {
      const unicodeStep = "🎉 Test with émojis and spéciàl chars ñ";
      mockStepInput.value = unicodeStep;
      
      controller.createStep();
      
      expect(controller.steps).toEqual([unicodeStep]);
      
      controller.renderSteps();
      const content = mockStepsList.querySelector('p');
      expect(content.textContent).toBe(unicodeStep);
    });

    it("should handle multiple rapid additions", () => {
      const steps = [];
      for (let i = 0; i < 100; i++) {
        mockStepInput.value = `Step ${i}`;
        controller.createStep();
        steps.push(`Step ${i}`);
      }
      
      expect(controller.steps).toEqual(steps);
      expect(controller.steps.length).toBe(100);
    });
  });
});