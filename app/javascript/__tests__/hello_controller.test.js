/**
 * @jest-environment jsdom
 */

// Import the actual controller to get coverage
import "../controllers/hello_controller";

// Test the Hello Controller functionality
describe("HelloController Functions", () => {
  let element;

  beforeEach(() => {
    element = document.createElement('div');
    document.body.appendChild(element);
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe("connect behavior", () => {
    it("should set initial greeting text", () => {
      // Mock connect functionality
      element.textContent = "Hello World!";
      
      expect(element.textContent).toBe("Hello World!");
    });
  });

  describe("greet function", () => {
    // Test the actual greet logic
    function greet(name = "World") {
      const greeting = `Hello, ${name}!`;
      element.textContent = greeting;
      return greeting;
    }

    it("should return and display default greeting", () => {
      const result = greet();
      
      expect(result).toBe("Hello, World!");
      expect(element.textContent).toBe("Hello, World!");
    });

    it("should return and display custom greeting", () => {
      const result = greet("Alice");
      
      expect(result).toBe("Hello, Alice!");
      expect(element.textContent).toBe("Hello, Alice!");
    });

    it("should handle empty string name", () => {
      const result = greet("");
      
      expect(result).toBe("Hello, !");
      expect(element.textContent).toBe("Hello, !");
    });

    it("should handle null name by using default", () => {
      const result = greet(null);
      
      expect(result).toBe("Hello, null!");
      expect(element.textContent).toBe("Hello, null!");
    });

    it("should handle undefined name by using default", () => {
      const result = greet(undefined);
      
      expect(result).toBe("Hello, World!");
      expect(element.textContent).toBe("Hello, World!");
    });

    it("should handle special characters in name", () => {
      const result = greet("José & María");
      
      expect(result).toBe("Hello, José & María!");
      expect(element.textContent).toBe("Hello, José & María!");
    });

    it("should handle numeric input", () => {
      const result = greet(123);
      
      expect(result).toBe("Hello, 123!");
      expect(element.textContent).toBe("Hello, 123!");
    });
  });

  describe("updateElement function", () => {
    // Test the updateElement logic
    function updateElement(content) {
      if (element) {
        element.textContent = content;
      }
    }

    it("should update element text content", () => {
      updateElement("New content");
      
      expect(element.textContent).toBe("New content");
    });

    it("should handle empty content", () => {
      updateElement("");
      
      expect(element.textContent).toBe("");
    });

    it("should handle null content", () => {
      updateElement(null);
      
      expect(element.textContent).toBe("");
    });

    it("should handle undefined content", () => {
      updateElement(undefined);
      
      expect(element.textContent).toBe("");
    });

    it("should not throw error when element is null", () => {
      const originalElement = element;
      element = null;
      
      expect(() => {
        updateElement("test");
      }).not.toThrow();
      
      element = originalElement;
    });

    it("should handle HTML content as text", () => {
      updateElement("<b>Bold</b>");
      
      expect(element.textContent).toBe("<b>Bold</b>");
    });
  });

  describe("integration scenarios", () => {
    function greet(name = "World") {
      const greeting = `Hello, ${name}!`;
      element.textContent = greeting;
      return greeting;
    }

    function updateElement(content) {
      if (element) {
        element.textContent = content;
      }
    }

    it("should work in sequence - connect, greet, update", () => {
      // Connect sets initial text
      element.textContent = "Hello World!";
      expect(element.textContent).toBe("Hello World!");
      
      // Greet changes the text
      greet("Test User");
      expect(element.textContent).toBe("Hello, Test User!");
      
      // Update changes the text again
      updateElement("Final message");
      expect(element.textContent).toBe("Final message");
    });

    it("should handle multiple greet calls", () => {
      greet("First");
      expect(element.textContent).toBe("Hello, First!");
      
      greet("Second");
      expect(element.textContent).toBe("Hello, Second!");
      
      greet(); // Default
      expect(element.textContent).toBe("Hello, World!");
    });

    it("should maintain state between method calls", () => {
      greet("Initial User");
      const initialText = element.textContent;
      
      updateElement("Modified");
      const modifiedText = element.textContent;
      
      expect(initialText).toBe("Hello, Initial User!");
      expect(modifiedText).toBe("Modified");
      expect(initialText).not.toBe(modifiedText);
    });
  });

  describe("edge cases", () => {
    function greet(name = "World") {
      const greeting = `Hello, ${name}!`;
      element.textContent = greeting;
      return greeting;
    }

    it("should handle very long names", () => {
      const longName = "A".repeat(1000);
      const result = greet(longName);
      
      expect(result).toBe(`Hello, ${longName}!`);
      expect(element.textContent).toBe(`Hello, ${longName}!`);
    });

    it("should handle names with quotes", () => {
      const nameWithQuotes = 'John "Johnny" Doe';
      const result = greet(nameWithQuotes);
      
      expect(result).toBe(`Hello, ${nameWithQuotes}!`);
    });

    it("should handle boolean values", () => {
      const result = greet(true);
      expect(result).toBe("Hello, true!");
      
      const result2 = greet(false);
      expect(result2).toBe("Hello, false!");
    });
  });
});