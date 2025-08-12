/**
 * @jest-environment jsdom
 */

import RichTextEditorController from "../controllers/rich_text_editor_controller"

describe("RichTextEditorController", () => {
  let controller;
  let mockElement;
  let mockEditorTarget;

  beforeEach(() => {
    mockElement = document.createElement('div');
    mockEditorTarget = document.createElement('textarea');
    mockEditorTarget.value = '';
    document.body.appendChild(mockElement);
    document.body.appendChild(mockEditorTarget);
    
    controller = new RichTextEditorController();
    
    // Mock the element and editorTarget
    Object.defineProperty(controller, 'element', {
      value: mockElement,
      writable: false,
      configurable: true
    });
    
    Object.defineProperty(controller, 'editorTarget', {
      value: mockEditorTarget,
      writable: false,
      configurable: true
    });
    
    Object.defineProperty(controller, 'contentValue', {
      value: '',
      writable: true,
      configurable: true
    });

    // Mock focus method
    mockEditorTarget.focus = jest.fn();
    
    // Mock prompt for testing
    global.prompt = jest.fn();
  });

  afterEach(() => {
    document.body.innerHTML = '';
    jest.clearAllMocks();
  });

  describe("connect behavior", () => {
    it("should call initializeEditor on connect", () => {
      const initSpy = jest.spyOn(controller, 'initializeEditor');
      
      controller.connect();
      
      expect(initSpy).toHaveBeenCalled();
    });
  });

  describe("disconnect behavior", () => {
    it("should destroy editor on disconnect", () => {
      // Mock editor object
      controller.editor = {
        destroy: jest.fn()
      };
      
      controller.disconnect();
      
      expect(controller.editor.destroy).toHaveBeenCalled();
    });

    it("should not throw when editor is undefined", () => {
      controller.editor = undefined;
      
      expect(() => {
        controller.disconnect();
      }).not.toThrow();
    });
  });

  describe("initializeEditor", () => {
    it("should create toolbar before editor", async () => {
      await controller.initializeEditor();
      
      const toolbar = mockEditorTarget.previousElementSibling;
      expect(toolbar).toBeTruthy();
      expect(toolbar.className).toContain('flex');
    });

    it("should create formatting buttons", async () => {
      await controller.initializeEditor();
      
      const toolbar = mockEditorTarget.previousElementSibling;
      const buttons = toolbar.querySelectorAll('button');
      
      expect(buttons.length).toBe(5); // Bold, Italic, Underline, List, Link
    });

    it("should modify editor styles", async () => {
      const originalClassName = mockEditorTarget.className;
      
      await controller.initializeEditor();
      
      expect(mockEditorTarget.className).toContain('rounded-t-none');
    });

    it("should set initial content if contentValue exists", async () => {
      controller.contentValue = "Initial content";
      
      await controller.initializeEditor();
      
      expect(mockEditorTarget.value).toBe("Initial content");
    });

    it("should not set content if contentValue is empty", async () => {
      controller.contentValue = "";
      
      await controller.initializeEditor();
      
      expect(mockEditorTarget.value).toBe("");
    });

    it("should handle null contentValue", async () => {
      controller.contentValue = null;
      
      expect(() => {
        controller.initializeEditor();
      }).not.toThrow();
    });
  });

  describe("bold formatting", () => {
    it("should wrap selected text with bold markers", () => {
      mockEditorTarget.value = "Hello world!";
      mockEditorTarget.selectionStart = 6;
      mockEditorTarget.selectionEnd = 11; // Select "world"
      
      controller.bold();
      
      expect(mockEditorTarget.value).toBe("Hello **world**!");
    });

    it("should add bold markers at cursor when no selection", () => {
      mockEditorTarget.value = "Hello !";
      mockEditorTarget.selectionStart = 6;
      mockEditorTarget.selectionEnd = 6;
      
      controller.bold();
      
      expect(mockEditorTarget.value).toBe("Hello ****!");
    });
  });

  describe("italic formatting", () => {
    it("should wrap selected text with italic markers", () => {
      mockEditorTarget.value = "This is important";
      mockEditorTarget.selectionStart = 8;
      mockEditorTarget.selectionEnd = 17; // Select "important"
      
      controller.italic();
      
      expect(mockEditorTarget.value).toBe("This is *important*");
    });

    it("should handle empty selection", () => {
      mockEditorTarget.value = "Text";
      mockEditorTarget.selectionStart = 4;
      mockEditorTarget.selectionEnd = 4;
      
      controller.italic();
      
      expect(mockEditorTarget.value).toBe("Text**");
    });
  });

  describe("underline formatting", () => {
    it("should wrap selected text with underline markers", () => {
      mockEditorTarget.value = "Underline this text";
      mockEditorTarget.selectionStart = 10;
      mockEditorTarget.selectionEnd = 14; // Select "this"
      
      controller.underline();
      
      expect(mockEditorTarget.value).toBe("Underline _this_ text");
    });
  });

  describe("insertList", () => {
    it("should insert bullet point at cursor", () => {
      mockEditorTarget.value = "Some text";
      mockEditorTarget.selectionStart = 9;
      
      controller.insertList();
      
      expect(mockEditorTarget.value).toBe("Some text\n• ");
      expect(mockEditorTarget.selectionStart).toBe(12);
      expect(mockEditorTarget.selectionEnd).toBe(12);
    });

    it("should insert bullet point in middle of text", () => {
      mockEditorTarget.value = "Before After";
      mockEditorTarget.selectionStart = 7;
      
      controller.insertList();
      
      expect(mockEditorTarget.value).toBe("Before \n• After");
    });
  });

  describe("insertLink", () => {
    it("should insert link with selected text", () => {
      global.prompt.mockReturnValue('https://example.com');
      
      mockEditorTarget.value = "Check out this website";
      mockEditorTarget.selectionStart = 10;
      mockEditorTarget.selectionEnd = 14; // Select "this"
      
      controller.insertLink();
      
      expect(mockEditorTarget.value).toBe("Check out [this](https://example.com) website");
      expect(global.prompt).toHaveBeenCalledWith('Enter URL:');
    });

    it("should insert empty link markers when no text selected", () => {
      global.prompt.mockReturnValue('https://example.com');
      
      mockEditorTarget.value = "Click here: ";
      mockEditorTarget.selectionStart = 12;
      mockEditorTarget.selectionEnd = 12;
      
      controller.insertLink();
      
      expect(mockEditorTarget.value).toBe("Click here: [](https://example.com)");
    });

    it("should not insert link when user cancels prompt", () => {
      global.prompt.mockReturnValue(null);
      
      mockEditorTarget.value = "No link here";
      mockEditorTarget.selectionStart = 8;
      mockEditorTarget.selectionEnd = 8;
      
      controller.insertLink();
      
      expect(mockEditorTarget.value).toBe("No link here");
    });

    it("should not insert link when URL is empty", () => {
      global.prompt.mockReturnValue('');
      
      mockEditorTarget.value = "Empty URL test";
      mockEditorTarget.selectionStart = 5;
      mockEditorTarget.selectionEnd = 8;
      
      controller.insertLink();
      
      expect(mockEditorTarget.value).toBe("Empty URL test");
    });
  });

  describe("wrapSelection helper", () => {
    it("should wrap selected text correctly", () => {
      mockEditorTarget.value = "Hello world!";
      mockEditorTarget.selectionStart = 0;
      mockEditorTarget.selectionEnd = 5; // Select "Hello"
      
      controller.wrapSelection('**', '**');
      
      expect(mockEditorTarget.value).toBe("**Hello** world!");
      expect(mockEditorTarget.selectionStart).toBe(2);
      expect(mockEditorTarget.selectionEnd).toBe(7);
    });

    it("should handle cursor positioning", () => {
      mockEditorTarget.value = "Test";
      mockEditorTarget.selectionStart = 4;
      mockEditorTarget.selectionEnd = 4;
      
      controller.wrapSelection('[', ']');
      
      expect(mockEditorTarget.value).toBe("Test[]");
      expect(mockEditorTarget.selectionStart).toBe(5);
      expect(mockEditorTarget.selectionEnd).toBe(5);
    });

    it("should focus editor after wrapping", () => {
      mockEditorTarget.value = "Text";
      mockEditorTarget.selectionStart = 0;
      mockEditorTarget.selectionEnd = 4;
      
      controller.wrapSelection('_', '_');
      
      expect(mockEditorTarget.focus).toHaveBeenCalled();
    });
  });

  describe("insertAtCursor helper", () => {
    it("should insert text at cursor position", () => {
      mockEditorTarget.value = "Before After";
      mockEditorTarget.selectionStart = 7;
      
      controller.insertAtCursor('MIDDLE ');
      
      expect(mockEditorTarget.value).toBe("Before MIDDLE After");
      expect(mockEditorTarget.selectionStart).toBe(14);
      expect(mockEditorTarget.selectionEnd).toBe(14);
    });

    it("should insert text at beginning", () => {
      mockEditorTarget.value = "Text";
      mockEditorTarget.selectionStart = 0;
      
      controller.insertAtCursor('START ');
      
      expect(mockEditorTarget.value).toBe("START Text");
    });

    it("should insert text at end", () => {
      mockEditorTarget.value = "Text";
      mockEditorTarget.selectionStart = 4;
      
      controller.insertAtCursor(' END');
      
      expect(mockEditorTarget.value).toBe("Text END");
    });

    it("should focus editor after insertion", () => {
      mockEditorTarget.value = "Text";
      mockEditorTarget.selectionStart = 4;
      
      controller.insertAtCursor(' more');
      
      expect(mockEditorTarget.focus).toHaveBeenCalled();
    });
  });

  describe("integration scenarios", () => {
    it("should handle multiple formatting operations", () => {
      mockEditorTarget.value = "Important text here";
      
      // Bold "Important"
      mockEditorTarget.selectionStart = 0;
      mockEditorTarget.selectionEnd = 9;
      controller.bold();
      
      expect(mockEditorTarget.value).toBe("**Important** text here");
      
      // Italic "text"
      mockEditorTarget.selectionStart = 14;
      mockEditorTarget.selectionEnd = 18;
      controller.italic();
      
      expect(mockEditorTarget.value).toBe("**Important** *text* here");
    });

    it("should handle list creation", () => {
      mockEditorTarget.value = "List items:";
      mockEditorTarget.selectionStart = 11;
      
      // Add first item
      controller.insertList();
      controller.insertAtCursor('First item');
      
      // Add second item
      controller.insertList();
      controller.insertAtCursor('Second item');
      
      expect(mockEditorTarget.value).toBe("List items:\n• First item\n• Second item");
    });

    it("should handle link with formatting", () => {
      global.prompt.mockReturnValue('https://example.com');
      
      mockEditorTarget.value = "Visit our site";
      mockEditorTarget.selectionStart = 6;
      mockEditorTarget.selectionEnd = 9; // Select "our"
      
      // First make it bold
      controller.bold();
      expect(mockEditorTarget.value).toBe("Visit **our** site");
      
      // Then make it a link
      mockEditorTarget.selectionStart = 6;
      mockEditorTarget.selectionEnd = 13; // Select "**our**"
      controller.insertLink();
      
      expect(mockEditorTarget.value).toBe("Visit [**our**](https://example.com) site");
    });
  });

  describe("edge cases", () => {
    it("should handle empty editor", () => {
      mockEditorTarget.value = "";
      mockEditorTarget.selectionStart = 0;
      mockEditorTarget.selectionEnd = 0;
      
      controller.bold();
      
      expect(mockEditorTarget.value).toBe("****");
    });

    it("should handle special characters in selection", () => {
      mockEditorTarget.value = "Text with & < > \" symbols";
      mockEditorTarget.selectionStart = 10;
      mockEditorTarget.selectionEnd = 25;
      
      controller.bold();
      
      expect(mockEditorTarget.value).toBe("Text with **& < > \" symbols**");
    });

    it("should handle very long text", () => {
      const longText = "A".repeat(1000);
      mockEditorTarget.value = longText;
      mockEditorTarget.selectionStart = 500;
      mockEditorTarget.selectionEnd = 600;
      
      controller.bold();
      
      expect(mockEditorTarget.value.length).toBe(1004); // Original + 4 characters (**)
    });

    it("should handle invalid selection ranges", () => {
      mockEditorTarget.value = "Test text";
      mockEditorTarget.selectionStart = 5;
      mockEditorTarget.selectionEnd = 3; // End before start
      
      expect(() => {
        controller.bold();
      }).not.toThrow();
    });

    it("should handle selection beyond text length", () => {
      mockEditorTarget.value = "Short";
      mockEditorTarget.selectionStart = 3;
      mockEditorTarget.selectionEnd = 100; // Beyond text length
      
      controller.bold();
      
      expect(mockEditorTarget.value).toBe("Sho**rt**");
    });
  });
});