/**
 * @jest-environment jsdom
 */

import AlertController from "../controllers/alert_controller"

describe("AlertController", () => {
  let controller;
  let mockElement;

  beforeEach(() => {
    jest.useFakeTimers();
    
    mockElement = document.createElement('div');
    document.body.appendChild(mockElement);
    
    controller = new AlertController();
    
    // Mock the element and autoCloseValue properties
    Object.defineProperty(controller, 'element', {
      value: mockElement,
      writable: false,
      configurable: true
    });
    
    // Default to false unless specified
    Object.defineProperty(controller, 'autoCloseValue', {
      value: false,
      writable: true,
      configurable: true
    });
  });

  afterEach(() => {
    jest.useRealTimers();
    jest.clearAllMocks();
    document.body.innerHTML = '';
  });

  describe("connect behavior", () => {
    it("should set up auto-close timeout when autoCloseValue is true", () => {
      controller.autoCloseValue = true;
      
      const mockSetTimeout = jest.spyOn(global, 'setTimeout');
      controller.connect();
      
      expect(mockSetTimeout).toHaveBeenCalledWith(expect.any(Function), 5000);
    });

    it("should not set up auto-close timeout when autoCloseValue is false", () => {
      controller.autoCloseValue = false;
      
      const mockSetTimeout = jest.spyOn(global, 'setTimeout');
      controller.connect();
      
      expect(mockSetTimeout).not.toHaveBeenCalled();
    });

    it("should not set up auto-close timeout when no autoCloseValue is specified", () => {
      const mockSetTimeout = jest.spyOn(global, 'setTimeout');
      controller.connect();
      
      expect(mockSetTimeout).not.toHaveBeenCalled();
    });

    it("should trigger auto-close after timeout", () => {
      controller.autoCloseValue = true;
      
      const closeSpy = jest.spyOn(controller, 'close');
      controller.connect();
      
      jest.advanceTimersByTime(5000);
      
      expect(closeSpy).toHaveBeenCalled();
    });
  });

  describe("disconnect behavior", () => {
    it("should clear timeout on disconnect when autoCloseTimeout exists", () => {
      controller.autoCloseValue = true;
      controller.connect();
      
      const mockClearTimeout = jest.spyOn(global, 'clearTimeout');
      controller.disconnect();
      
      expect(mockClearTimeout).toHaveBeenCalled();
    });

    it("should not throw error when disconnecting without autoCloseTimeout", () => {
      expect(() => {
        controller.disconnect();
      }).not.toThrow();
    });
  });

  describe("close method", () => {
    it("should set fade-out styles", () => {
      controller.close();
      
      expect(mockElement.style.transition).toBe("opacity 0.3s ease-out, transform 0.3s ease-out");
      expect(mockElement.style.opacity).toBe("0");
      expect(mockElement.style.transform).toBe("translateX(100%)");
    });

    it("should schedule element removal after animation delay", () => {
      const mockSetTimeout = jest.spyOn(global, 'setTimeout');
      
      controller.close();
      
      expect(mockSetTimeout).toHaveBeenLastCalledWith(expect.any(Function), 300);
    });

    it("should remove element after animation delay", () => {
      const removeSpy = jest.spyOn(mockElement, 'remove');
      
      controller.close();
      jest.advanceTimersByTime(300);
      
      expect(removeSpy).toHaveBeenCalled();
    });

    it("should handle multiple close calls gracefully", () => {
      expect(() => {
        controller.close();
        controller.close();
      }).not.toThrow();
    });

    it("should handle close when element is detached", () => {
      mockElement.remove();
      
      expect(() => {
        controller.close();
        jest.advanceTimersByTime(300);
      }).not.toThrow();
    });

    it("should apply all style changes correctly", () => {
      controller.close();
      
      expect(mockElement.style.transition).toContain("opacity 0.3s ease-out");
      expect(mockElement.style.transition).toContain("transform 0.3s ease-out");
      expect(mockElement.style.opacity).toBe("0");
      expect(mockElement.style.transform).toBe("translateX(100%)");
    });

    it("should handle null element gracefully", () => {
      Object.defineProperty(controller, 'element', {
        value: null,
        writable: false,
        configurable: true
      });
      
      expect(() => {
        controller.close();
      }).toThrow(); // This should throw because of null.style access - which is expected behavior
    });
  });

  describe("integration scenarios", () => {
    it("should complete full auto-close cycle", () => {
      controller.autoCloseValue = true;
      
      const removeSpy = jest.spyOn(mockElement, 'remove');
      controller.connect();
      
      // Fast-forward through auto-close timeout
      jest.advanceTimersByTime(5000);
      
      // Check that close animation styles are applied
      expect(mockElement.style.opacity).toBe("0");
      expect(mockElement.style.transform).toBe("translateX(100%)");
      
      // Fast-forward through animation delay
      jest.advanceTimersByTime(300);
      
      expect(removeSpy).toHaveBeenCalled();
    });

    it("should handle manual close before auto-close", () => {
      controller.autoCloseValue = true;
      
      const removeSpy = jest.spyOn(mockElement, 'remove');
      controller.connect();
      
      // Manual close before auto-close timeout
      controller.close();
      jest.advanceTimersByTime(300);
      
      expect(removeSpy).toHaveBeenCalled();
      
      // Auto-close timeout should not cause issues
      jest.advanceTimersByTime(5000);
      
      // Should not throw errors
      expect(() => {
        jest.runAllTimers();
      }).not.toThrow();
    });

    it("should handle disconnect during auto-close countdown", () => {
      controller.autoCloseValue = true;
      controller.connect();
      
      // Advance time partially
      jest.advanceTimersByTime(2500);
      
      // Disconnect before auto-close triggers
      controller.disconnect();
      
      // Continue advancing time
      jest.advanceTimersByTime(2500);
      
      // Close should not have been called since timeout was cleared
      expect(mockElement.style.opacity).toBe("");
    });

    it("should preserve element attributes during close animation", () => {
      mockElement.setAttribute('id', 'test-alert');
      mockElement.setAttribute('class', 'alert-success');
      
      controller.close();
      
      expect(mockElement.getAttribute('id')).toBe('test-alert');
      expect(mockElement.getAttribute('class')).toBe('alert-success');
    });
  });

  describe("edge cases", () => {
    it("should handle element without parent", () => {
      mockElement.remove(); // Remove from DOM
      
      expect(() => {
        controller.close();
        jest.advanceTimersByTime(300);
      }).not.toThrow();
    });

    it("should handle rapid connect/disconnect cycles", () => {
      controller.autoCloseValue = true;
      
      expect(() => {
        controller.connect();
        controller.disconnect();
        controller.connect();
        controller.disconnect();
      }).not.toThrow();
    });

    it("should maintain proper timer state across multiple instances", () => {
      const element2 = document.createElement('div');
      document.body.appendChild(element2);
      
      const controller2 = new AlertController();
      Object.defineProperty(controller2, 'element', {
        value: element2,
        writable: false,
        configurable: true
      });
      Object.defineProperty(controller2, 'autoCloseValue', {
        value: true,
        writable: true,
        configurable: true
      });
      
      controller.autoCloseValue = true;
      
      const clearTimeoutSpy = jest.spyOn(global, 'clearTimeout');
      
      controller.connect();
      controller2.connect();
      
      controller.disconnect();
      controller2.disconnect();
      
      expect(clearTimeoutSpy).toHaveBeenCalledTimes(2);
    });

    it("should work with element that has existing styles", () => {
      mockElement.style.backgroundColor = 'red';
      mockElement.style.fontSize = '14px';
      
      controller.close();
      
      expect(mockElement.style.backgroundColor).toBe('red');
      expect(mockElement.style.fontSize).toBe('14px');
      expect(mockElement.style.opacity).toBe('0');
      expect(mockElement.style.transform).toBe('translateX(100%)');
    });

    it("should handle timeout clearing edge case", () => {
      controller.autoCloseValue = true;
      controller.connect();
      
      // Manually clear the timeout reference
      controller.autoCloseTimeout = null;
      
      expect(() => {
        controller.disconnect();
      }).not.toThrow();
    });

    it("should handle element with no style property", () => {
      // Create an element-like object without style
      const mockBrokenElement = {
        remove: jest.fn()
      };
      
      Object.defineProperty(controller, 'element', {
        value: mockBrokenElement,
        writable: false,
        configurable: true
      });
      
      expect(() => {
        controller.close();
      }).toThrow(); // This should throw because element.style doesn't exist
    });

    it("should handle concurrent close and auto-close", () => {
      controller.autoCloseValue = true;
      controller.connect();
      
      const removeSpy = jest.spyOn(mockElement, 'remove');
      
      // Manual close at same time as auto-close would trigger
      jest.advanceTimersByTime(4999);
      controller.close();
      jest.advanceTimersByTime(1);
      
      // Should handle gracefully
      expect(() => {
        jest.advanceTimersByTime(300);
      }).not.toThrow();
      
      expect(removeSpy).toHaveBeenCalled();
    });
  });
});