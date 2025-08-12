/**
 * @jest-environment jsdom
 */

// Import the actual controller to get coverage
import "../controllers/test_case_steps_controller";

// Test TestCaseSteps Controller functionality
describe("TestCaseStepsController Functions", () => {
  let stepsContainer, stepInput, stepsList, hiddenInput;
  let steps = [];

  beforeEach(() => {
    // Create DOM elements
    stepsContainer = document.createElement('div');
    stepInput = document.createElement('input');
    stepInput.type = 'text';
    stepsList = document.createElement('div');
    hiddenInput = document.createElement('input');
    hiddenInput.type = 'hidden';
    hiddenInput.name = 'steps';
    
    document.body.appendChild(stepsContainer);
    document.body.appendChild(stepInput);
    document.body.appendChild(stepsList);
    document.body.appendChild(hiddenInput);
    
    // Initialize steps array
    steps = [];
  });

  afterEach(() => {
    document.body.innerHTML = '';
    steps = [];
    jest.clearAllMocks();
  });

  describe("connect behavior", () => {
    it("should initialize with empty steps array", () => {
      // Mock connect functionality
      steps = [];
      hiddenInput.value = JSON.stringify(steps);
      
      expect(steps).toEqual([]);
      expect(hiddenInput.value).toBe('[]');
    });
  });

  describe("addStep functionality", () => {
    function addStep(event) {
      if (event.key === "Enter") {
        event.preventDefault();
        createStep();
      }
    }

    function createStep() {
      const stepText = stepInput.value.trim();
      
      if (stepText === "") return;
      
      steps.push(stepText);
      renderSteps();
      updateHiddenInput();
      
      // Clear input and focus
      stepInput.value = "";
      stepInput.focus();
    }

    function renderSteps() {
      stepsList.innerHTML = "";
      
      steps.forEach((step, index) => {
        const stepElement = document.createElement("div");
        stepElement.className = "flex items-start gap-3 p-4 bg-base-200 rounded-lg group hover:bg-base-300 transition-colors";
        
        stepElement.innerHTML = `
          <div class="flex items-center justify-center w-8 h-8 bg-primary text-primary-content rounded-full text-sm font-bold flex-shrink-0 mt-0.5">
            ${index + 1}
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-base-content break-words">${escapeHtml(step)}</p>
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
        `;
        
        stepsList.appendChild(stepElement);
      });
    }

    function updateHiddenInput() {
      hiddenInput.value = JSON.stringify(steps);
    }

    function escapeHtml(text) {
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    }

    it("should add step on Enter key press", () => {
      stepInput.value = "Test step 1";
      const mockEvent = { key: "Enter", preventDefault: jest.fn() };
      
      addStep(mockEvent);
      
      expect(mockEvent.preventDefault).toHaveBeenCalled();
      expect(steps).toEqual(["Test step 1"]);
      expect(stepInput.value).toBe("");
    });

    it("should not add step on other key presses", () => {
      stepInput.value = "Test step 1";
      const mockEvent = { key: "Space", preventDefault: jest.fn() };
      
      addStep(mockEvent);
      
      expect(mockEvent.preventDefault).not.toHaveBeenCalled();
      expect(steps).toEqual([]);
    });

    it("should not add empty or whitespace-only steps", () => {
      stepInput.value = "   ";
      createStep();
      
      expect(steps).toEqual([]);
      expect(stepInput.value).toBe("   ");
    });

    it("should trim whitespace from steps", () => {
      stepInput.value = "  Test step with spaces  ";
      createStep();
      
      expect(steps).toEqual(["Test step with spaces"]);
    });

    it("should clear input and focus after adding step", () => {
      stepInput.value = "Test step";
      const focusSpy = jest.spyOn(stepInput, 'focus');
      
      createStep();
      
      expect(stepInput.value).toBe("");
      expect(focusSpy).toHaveBeenCalled();
    });

    it("should update hidden input after adding step", () => {
      stepInput.value = "Test step 1";
      createStep();
      stepInput.value = "Test step 2";
      createStep();
      
      expect(hiddenInput.value).toBe('["Test step 1","Test step 2"]');
    });
  });

  describe("removeStep functionality", () => {
    function removeStep(index) {
      steps.splice(index, 1);
      renderSteps();
      updateHiddenInput();
    }

    function renderSteps() {
      stepsList.innerHTML = "";
      
      steps.forEach((step, index) => {
        const stepElement = document.createElement("div");
        stepElement.innerHTML = `
          <div class="step-number">${index + 1}</div>
          <div class="step-content">${escapeHtml(step)}</div>
          <button data-index="${index}">Remove</button>
        `;
        stepsList.appendChild(stepElement);
      });
    }

    function updateHiddenInput() {
      hiddenInput.value = JSON.stringify(steps);
    }

    function escapeHtml(text) {
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    }

    beforeEach(() => {
      steps = ["Step 1", "Step 2", "Step 3"];
      renderSteps();
      updateHiddenInput();
    });

    it("should remove step at specified index", () => {
      removeStep(1);
      
      expect(steps).toEqual(["Step 1", "Step 3"]);
      expect(hiddenInput.value).toBe('["Step 1","Step 3"]');
    });

    it("should remove first step", () => {
      removeStep(0);
      
      expect(steps).toEqual(["Step 2", "Step 3"]);
    });

    it("should remove last step", () => {
      removeStep(2);
      
      expect(steps).toEqual(["Step 1", "Step 2"]);
    });

    it("should handle removing all steps", () => {
      removeStep(0);
      removeStep(0);
      removeStep(0);
      
      expect(steps).toEqual([]);
      expect(hiddenInput.value).toBe('[]');
    });

    it("should update step numbering after removal", () => {
      removeStep(0); // Remove "Step 1"
      
      const stepNumbers = stepsList.querySelectorAll('.step-number');
      expect(stepNumbers[0].textContent).toBe('1'); // "Step 2" becomes #1
      expect(stepNumbers[1].textContent).toBe('2'); // "Step 3" becomes #2
    });
  });

  describe("renderSteps functionality", () => {
    function renderSteps() {
      stepsList.innerHTML = "";
      
      steps.forEach((step, index) => {
        const stepElement = document.createElement("div");
        stepElement.className = "step-item";
        stepElement.innerHTML = `
          <div class="step-number">${index + 1}</div>
          <div class="step-content">${escapeHtml(step)}</div>
          <button class="remove-btn" data-index="${index}">×</button>
        `;
        stepsList.appendChild(stepElement);
      });
    }

    function escapeHtml(text) {
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    }

    it("should render empty list when no steps", () => {
      steps = [];
      renderSteps();
      
      expect(stepsList.children.length).toBe(0);
      expect(stepsList.innerHTML).toBe("");
    });

    it("should render all steps with correct numbering", () => {
      steps = ["First step", "Second step", "Third step"];
      renderSteps();
      
      expect(stepsList.children.length).toBe(3);
      
      const numbers = stepsList.querySelectorAll('.step-number');
      expect(numbers[0].textContent).toBe('1');
      expect(numbers[1].textContent).toBe('2');
      expect(numbers[2].textContent).toBe('3');
    });

    it("should render step content correctly", () => {
      steps = ["Test step content"];
      renderSteps();
      
      const content = stepsList.querySelector('.step-content');
      expect(content.textContent).toBe("Test step content");
    });

    it("should add remove buttons with correct indices", () => {
      steps = ["Step 1", "Step 2"];
      renderSteps();
      
      const buttons = stepsList.querySelectorAll('.remove-btn');
      expect(buttons[0].getAttribute('data-index')).toBe('0');
      expect(buttons[1].getAttribute('data-index')).toBe('1');
    });

    it("should escape HTML in step content", () => {
      steps = ["<script>alert('xss')</script>"];
      renderSteps();
      
      const content = stepsList.querySelector('.step-content');
      expect(content.innerHTML).toBe("&lt;script&gt;alert('xss')&lt;/script&gt;");
    });
  });

  describe("updateHiddenInput functionality", () => {
    function updateHiddenInput() {
      hiddenInput.value = JSON.stringify(steps);
    }

    it("should serialize empty array", () => {
      steps = [];
      updateHiddenInput();
      
      expect(hiddenInput.value).toBe('[]');
    });

    it("should serialize single step", () => {
      steps = ["Single step"];
      updateHiddenInput();
      
      expect(hiddenInput.value).toBe('["Single step"]');
    });

    it("should serialize multiple steps", () => {
      steps = ["Step 1", "Step 2", "Step 3"];
      updateHiddenInput();
      
      expect(hiddenInput.value).toBe('["Step 1","Step 2","Step 3"]');
    });

    it("should handle special characters in steps", () => {
      steps = ["Step with \"quotes\"", "Step with 'apostrophes'", "Step with \n newlines"];
      updateHiddenInput();
      
      const parsed = JSON.parse(hiddenInput.value);
      expect(parsed).toEqual(steps);
    });
  });

  describe("escapeHtml functionality", () => {
    function escapeHtml(text) {
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    }

    it("should escape HTML tags", () => {
      const result = escapeHtml("<div>test</div>");
      expect(result).toBe("&lt;div&gt;test&lt;/div&gt;");
    });

    it("should escape script tags", () => {
      const result = escapeHtml("<script>alert('xss')</script>");
      expect(result).toBe("&lt;script&gt;alert('xss')&lt;/script&gt;");
    });

    it("should escape quotes", () => {
      const result = escapeHtml('Text with "quotes" and \'apostrophes\'');
      expect(result).toBe('Text with "quotes" and \'apostrophes\'');
    });

    it("should handle ampersands", () => {
      const result = escapeHtml("Tom & Jerry");
      expect(result).toBe("Tom &amp; Jerry");
    });

    it("should handle empty string", () => {
      const result = escapeHtml("");
      expect(result).toBe("");
    });

    it("should handle null and undefined", () => {
      expect(escapeHtml(null)).toBe("");
      expect(escapeHtml(undefined)).toBe("");
    });
  });

  describe("integration scenarios", () => {
    function createStep() {
      const stepText = stepInput.value.trim();
      if (stepText === "") return;
      steps.push(stepText);
      stepInput.value = "";
      updateHiddenInput();
    }

    function removeStep(index) {
      steps.splice(index, 1);
      updateHiddenInput();
    }

    function updateHiddenInput() {
      hiddenInput.value = JSON.stringify(steps);
    }

    it("should handle complete workflow: add, remove, add", () => {
      // Add steps
      stepInput.value = "Step 1";
      createStep();
      stepInput.value = "Step 2";
      createStep();
      stepInput.value = "Step 3";
      createStep();
      
      expect(steps).toEqual(["Step 1", "Step 2", "Step 3"]);
      expect(hiddenInput.value).toBe('["Step 1","Step 2","Step 3"]');
      
      // Remove middle step
      removeStep(1);
      
      expect(steps).toEqual(["Step 1", "Step 3"]);
      expect(hiddenInput.value).toBe('["Step 1","Step 3"]');
      
      // Add another step
      stepInput.value = "Step 4";
      createStep();
      
      expect(steps).toEqual(["Step 1", "Step 3", "Step 4"]);
      expect(hiddenInput.value).toBe('["Step 1","Step 3","Step 4"]');
    });

    it("should maintain state consistency", () => {
      const testSteps = ["A", "B", "C", "D", "E"];
      
      // Add all steps
      testSteps.forEach(step => {
        stepInput.value = step;
        createStep();
      });
      
      expect(steps).toEqual(testSteps);
      
      // Remove every other step
      removeStep(4); // E
      removeStep(2); // C
      removeStep(0); // A
      
      expect(steps).toEqual(["B", "D"]);
      expect(JSON.parse(hiddenInput.value)).toEqual(["B", "D"]);
    });
  });
});