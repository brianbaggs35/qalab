/**
 * @jest-environment jsdom
 */

import HelloController from "../controllers/hello_controller"

// Test the Hello Controller functionality
describe("HelloController", () => {
  let controller;
  let mockElement;

  beforeEach(() => {
    mockElement = document.createElement('div');
    document.body.appendChild(mockElement);
    
    controller = new HelloController();
    // Use Object.defineProperty to mock the element getter
    Object.defineProperty(controller, 'element', {
      value: mockElement,
      writable: false,
      configurable: true
    });
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe("connect behavior", () => {
    it("should set initial greeting text on connect", () => {
      controller.connect();
      expect(mockElement.textContent).toBe("Hello World!");
    });
  });

  describe("greet method", () => {
    it("should return and display default greeting", () => {
      const result = controller.greet();
      
      expect(result).toBe("Hello, World!");
      expect(mockElement.textContent).toBe("Hello, World!");
    });

    it("should return and display custom greeting", () => {
      const result = controller.greet("Alice");
      
      expect(result).toBe("Hello, Alice!");
      expect(mockElement.textContent).toBe("Hello, Alice!");
    });

    it("should handle empty string name", () => {
      const result = controller.greet("");
      
      expect(result).toBe("Hello, !");
      expect(mockElement.textContent).toBe("Hello, !");
    });

    it("should handle null name", () => {
      const result = controller.greet(null);
      
      expect(result).toBe("Hello, null!");
      expect(mockElement.textContent).toBe("Hello, null!");
    });

    it("should handle undefined name by using default", () => {
      const result = controller.greet(undefined);
      
      expect(result).toBe("Hello, World!");
      expect(mockElement.textContent).toBe("Hello, World!");
    });

    it("should handle special characters in name", () => {
      const result = controller.greet("José & María");
      
      expect(result).toBe("Hello, José & María!");
      expect(mockElement.textContent).toBe("Hello, José & María!");
    });

    it("should handle numeric input", () => {
      const result = controller.greet(123);
      
      expect(result).toBe("Hello, 123!");
      expect(mockElement.textContent).toBe("Hello, 123!");
    });

    it("should handle boolean values", () => {
      const result = controller.greet(true);
      expect(result).toBe("Hello, true!");
      
      const result2 = controller.greet(false);
      expect(result2).toBe("Hello, false!");
    });

    it("should handle very long names", () => {
      const longName = "A".repeat(1000);
      const result = controller.greet(longName);
      
      expect(result).toBe(`Hello, ${longName}!`);
      expect(mockElement.textContent).toBe(`Hello, ${longName}!`);
    });

    it("should handle names with quotes", () => {
      const nameWithQuotes = 'John "Johnny" Doe';
      const result = controller.greet(nameWithQuotes);
      
      expect(result).toBe(`Hello, ${nameWithQuotes}!`);
    });
  });

  describe("updateElement method", () => {
    it("should update element text content", () => {
      controller.updateElement("New content");
      
      expect(mockElement.textContent).toBe("New content");
    });

    it("should handle empty content", () => {
      controller.updateElement("");
      
      expect(mockElement.textContent).toBe("");
    });

    it("should handle null content", () => {
      controller.updateElement(null);
      
      expect(mockElement.textContent).toBe(""); // null becomes empty string in textContent
    });

    it("should handle undefined content", () => {
      controller.updateElement(undefined);
      
      expect(mockElement.textContent).toBe(""); // undefined becomes empty string in textContent
    });

    it("should handle HTML content as text", () => {
      controller.updateElement("<b>Bold</b>");
      
      expect(mockElement.textContent).toBe("<b>Bold</b>");
    });

    it("should not throw error when element is null", () => {
      // Mock element as null
      Object.defineProperty(controller, 'element', {
        value: null,
        writable: false,
        configurable: true
      });
      
      expect(() => {
        controller.updateElement("test");
      }).not.toThrow();
    });
  });

  describe("disconnect behavior", () => {
    it("should handle disconnect gracefully", () => {
      expect(() => {
        controller.disconnect();
      }).not.toThrow();
    });
  });

  describe("integration scenarios", () => {
    it("should work in sequence - connect, greet, update", () => {
      // Simulate connect
      controller.connect();
      expect(mockElement.textContent).toBe("Hello World!");
      
      // Greet changes the text
      controller.greet("Test User");
      expect(mockElement.textContent).toBe("Hello, Test User!");
      
      // Update changes the text again
      controller.updateElement("Final message");
      expect(mockElement.textContent).toBe("Final message");
    });

    it("should handle multiple greet calls", () => {
      controller.greet("First");
      expect(mockElement.textContent).toBe("Hello, First!");
      
      controller.greet("Second");
      expect(mockElement.textContent).toBe("Hello, Second!");
      
      controller.greet(); // Default
      expect(mockElement.textContent).toBe("Hello, World!");
    });

    it("should maintain state between method calls", () => {
      controller.greet("Initial User");
      const initialText = mockElement.textContent;
      
      controller.updateElement("Modified");
      const modifiedText = mockElement.textContent;
      
      expect(initialText).toBe("Hello, Initial User!");
      expect(modifiedText).toBe("Modified");
      expect(initialText).not.toBe(modifiedText);
    });

    it("should preserve element reference", () => {
      const originalElement = controller.element;
      
      controller.greet("Test");
      expect(controller.element).toBe(originalElement);
      expect(mockElement.textContent).toBe("Hello, Test!");
      
      controller.updateElement("Updated");
      expect(controller.element).toBe(originalElement);
      expect(mockElement.textContent).toBe("Updated");
    });
  });

  describe("edge cases", () => {
    it("should handle element being reassigned between calls", () => {
      const newElement = document.createElement('div');
      document.body.appendChild(newElement);
      
      controller.greet("First");
      expect(mockElement.textContent).toBe("Hello, First!");
      
      // Reassign element
      Object.defineProperty(controller, 'element', {
        value: newElement,
        writable: false,
        configurable: true
      });
      
      controller.greet("Second");
      expect(newElement.textContent).toBe("Hello, Second!");
      expect(mockElement.textContent).toBe("Hello, First!"); // Original unchanged
    });

    it("should handle element with existing content", () => {
      mockElement.textContent = "Existing content";
      
      controller.greet("New");
      expect(mockElement.textContent).toBe("Hello, New!");
    });

    it("should handle element in different contexts", () => {
      // Test with different element types
      const spanElement = document.createElement('span');
      Object.defineProperty(controller, 'element', {
        value: spanElement,
        writable: false,
        configurable: true
      });
      
      controller.greet("Span test");
      expect(spanElement.textContent).toBe("Hello, Span test!");
    });
  });
});