/**
 * @jest-environment jsdom
 */

// Test that application.js exports what we expect
describe("application.js", () => {
  // Mock @hotwired/stimulus before importing
  const mockApplication = {
    debug: false,
    start: jest.fn().mockReturnThis(),
    register: jest.fn(),
    stop: jest.fn()
  };

  const mockApplicationStart = jest.fn(() => mockApplication);

  beforeEach(() => {
    jest.doMock('@hotwired/stimulus', () => ({
      Application: {
        start: mockApplicationStart
      }
    }));
    
    // Clear window.Stimulus
    delete global.window?.Stimulus;
    
    jest.clearAllMocks();
  });

  afterEach(() => {
    jest.resetModules();
  });

  it("should create a Stimulus application", () => {
    const { application } = require("../controllers/application");
    
    expect(mockApplicationStart).toHaveBeenCalled();
    expect(application).toBe(mockApplication);
  });

  it("should set debug to false", () => {
    require("../controllers/application");
    
    expect(mockApplication.debug).toBe(false);
  });

  it("should set window.Stimulus to the application", () => {
    const { application } = require("../controllers/application");
    
    expect(global.window.Stimulus).toBe(application);
  });

  it("should export the application", () => {
    const { application } = require("../controllers/application");
    
    expect(application).toBeDefined();
    expect(typeof application.register).toBe('function');
    expect(typeof application.start).toBe('function');
    expect(typeof application.stop).toBe('function');
  });

  describe("application configuration", () => {
    it("should allow registering controllers", () => {
      const { application } = require("../controllers/application");
      
      // Mock controller
      class TestController {
        static targets = ["test"];
        connect() {}
      }
      
      expect(() => {
        application.register("test", TestController);
      }).not.toThrow();
      
      expect(application.register).toHaveBeenCalledWith("test", TestController);
    });

    it("should allow stopping and starting", () => {
      const { application } = require("../controllers/application");
      
      expect(() => {
        application.stop();
        application.start();
      }).not.toThrow();
      
      expect(application.stop).toHaveBeenCalled();
      expect(application.start).toHaveBeenCalled();
    });
  });

  describe("module loading", () => {
    it("should not throw errors when imported", () => {
      expect(() => {
        require("../controllers/application");
      }).not.toThrow();
    });

    it("should be importable multiple times", () => {
      const module1 = require("../controllers/application");
      const module2 = require("../controllers/application");
      
      expect(module1.application).toBe(module2.application);
    });
  });

  describe("window.Stimulus global", () => {
    it("should make Stimulus available globally for debugging", () => {
      const { application } = require("../controllers/application");
      
      expect(global.window.Stimulus).toBeDefined();
      expect(global.window.Stimulus).toBe(application);
    });

    it("should overwrite existing window.Stimulus", () => {
      const existingStimulus = { existing: true };
      global.window.Stimulus = existingStimulus;
      
      const { application } = require("../controllers/application");
      
      expect(global.window.Stimulus).toBe(application);
      expect(global.window.Stimulus).not.toBe(existingStimulus);
    });
  });
});