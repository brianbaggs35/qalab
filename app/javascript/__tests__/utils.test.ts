/// <reference types="jest" />
/// <reference types="node" />

import { UIHelpers, ApiClient, UserData, OrganizationData } from '../utils/index';

// Mock DOM and fetch for testing
declare global {
  namespace NodeJS {
    interface Global {
      fetch: jest.MockedFunction<typeof fetch>;
      FormData: jest.MockedClass<typeof FormData>;
    }
  }
}

// Mock fetch globally
const mockFetch = jest.fn();
global.fetch = mockFetch as any;

// Mock DOM methods
const mockAppendChild = jest.fn();
const mockRemoveChild = jest.fn();

Object.defineProperty(document, 'createElement', {
  writable: true,
  value: jest.fn(() => ({
    className: '',
    textContent: '',
    style: { display: '' },
    parentNode: {
      removeChild: mockRemoveChild
    }
  })),
});

Object.defineProperty(document, 'body', {
  writable: true,
  value: {
    appendChild: mockAppendChild,
  },
});

describe('UIHelpers', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  describe('showNotification', () => {
    it('should create and append notification element with default type', () => {
      const createElement = document.createElement as jest.Mock;
      const mockElement = {
        className: '',
        textContent: '',
        parentNode: { removeChild: jest.fn() }
      };
      createElement.mockReturnValue(mockElement);

      UIHelpers.showNotification('Test message');

      expect(createElement).toHaveBeenCalledWith('div');
      expect(mockElement.className).toBe('notification notification-info');
      expect(mockElement.textContent).toBe('Test message');
      expect(mockAppendChild).toHaveBeenCalledWith(mockElement);
    });

    it('should create notification with custom type', () => {
      const createElement = document.createElement as jest.Mock;
      const mockElement = {
        className: '',
        textContent: '',
        parentNode: { removeChild: jest.fn() }
      };
      createElement.mockReturnValue(mockElement);

      UIHelpers.showNotification('Success message', 'success');

      expect(mockElement.className).toBe('notification notification-success');
      expect(mockElement.textContent).toBe('Success message');
    });

    it('should auto-remove notification after 5 seconds', () => {
      const createElement = document.createElement as jest.Mock;
      const mockElement = {
        className: '',
        textContent: '',
        parentNode: { removeChild: jest.fn() }
      };
      createElement.mockReturnValue(mockElement);

      UIHelpers.showNotification('Test message');

      // Fast-forward time by 5 seconds
      jest.advanceTimersByTime(5000);

      expect(mockElement.parentNode.removeChild).toHaveBeenCalledWith(mockElement);
    });

    it('should handle case where element has no parent node', () => {
      const createElement = document.createElement as jest.Mock;
      const mockElement = {
        className: '',
        textContent: '',
        parentNode: null
      };
      createElement.mockReturnValue(mockElement);

      UIHelpers.showNotification('Test message');

      // Fast-forward time by 5 seconds
      jest.advanceTimersByTime(5000);

      // Should not throw an error
      expect(() => jest.runAllTimers()).not.toThrow();
    });
  });

  describe('formatDate', () => {
    it('should format Date object', () => {
      const date = new Date('2024-01-15');
      const result = UIHelpers.formatDate(date);
      expect(result).toMatch(/Jan 1[45], 2024/); // Account for timezone differences
    });

    it('should format date string', () => {
      const result = UIHelpers.formatDate('2024-01-15');
      expect(result).toMatch(/Jan 1[45], 2024/); // Account for timezone differences
    });
  });

  describe('isValidEmail', () => {
    it('should return true for valid email addresses', () => {
      expect(UIHelpers.isValidEmail('test@example.com')).toBe(true);
      expect(UIHelpers.isValidEmail('user.name@domain.co.uk')).toBe(true);
      expect(UIHelpers.isValidEmail('test+tag@example.org')).toBe(true);
    });

    it('should return false for invalid email addresses', () => {
      expect(UIHelpers.isValidEmail('invalid-email')).toBe(false);
      expect(UIHelpers.isValidEmail('test@')).toBe(false);
      expect(UIHelpers.isValidEmail('@example.com')).toBe(false);
      expect(UIHelpers.isValidEmail('test..test@example.com')).toBe(false);
      expect(UIHelpers.isValidEmail('')).toBe(false);
    });
  });

  describe('toggleElement', () => {
    it('should toggle element visibility from visible to hidden', () => {
      const mockElement = {
        style: { display: '' }
      } as HTMLElement;

      UIHelpers.toggleElement(mockElement);
      expect(mockElement.style.display).toBe('none');
    });

    it('should toggle element visibility from hidden to visible', () => {
      const mockElement = {
        style: { display: 'none' }
      } as HTMLElement;

      UIHelpers.toggleElement(mockElement);
      expect(mockElement.style.display).toBe('');
    });

    it('should handle null element gracefully', () => {
      expect(() => UIHelpers.toggleElement(null)).not.toThrow();
    });
  });

  describe('getFormData', () => {
    it('should extract form data as object', () => {
      const mockFormData = new Map([
        ['name', 'John Doe'],
        ['email', 'john@example.com']
      ]);

      // Mock FormData
      (global as any).FormData = jest.fn().mockImplementation(() => ({
        forEach: (callback: (value: string, key: string) => void) => {
          mockFormData.forEach((value, key) => callback(value, key));
        }
      }));

      const mockForm = {} as HTMLFormElement;
      const result = UIHelpers.getFormData(mockForm);

      expect(result).toEqual({
        name: 'John Doe',
        email: 'john@example.com'
      });
    });
  });
});

describe('ApiClient', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockFetch.mockClear();
  });

  describe('constructor', () => {
    it('should use default baseUrl if not provided', () => {
      const client = new ApiClient();
      expect(client).toBeInstanceOf(ApiClient);
    });

    it('should use provided baseUrl', () => {
      const client = new ApiClient('/custom-api');
      expect(client).toBeInstanceOf(ApiClient);
    });
  });

  describe('get', () => {
    it('should make GET request and return JSON', async () => {
      const mockResponse = { id: 1, name: 'Test' };
      mockFetch.mockResolvedValue({
        ok: true,
        json: () => Promise.resolve(mockResponse),
      } as Response);

      const client = new ApiClient();
      const result = await client.get('/test');

      expect(mockFetch).toHaveBeenCalledWith('/api/test');
      expect(result).toEqual(mockResponse);
    });

    it('should throw error for non-ok response', async () => {
      mockFetch.mockResolvedValue({
        ok: false,
        status: 404,
      } as Response);

      const client = new ApiClient();
      await expect(client.get('/test')).rejects.toThrow('HTTP error! status: 404');
    });
  });

  describe('post', () => {
    it('should make POST request with data', async () => {
      const mockResponse = { id: 1, name: 'Created' };
      const postData = { name: 'Test', email: 'test@example.com' };

      mockFetch.mockResolvedValue({
        ok: true,
        json: () => Promise.resolve(mockResponse),
      } as Response);

      const client = new ApiClient();
      const result = await client.post('/users', postData);

      expect(mockFetch).toHaveBeenCalledWith('/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(postData),
      });
      expect(result).toEqual(mockResponse);
    });

    it('should throw error for non-ok POST response', async () => {
      mockFetch.mockResolvedValue({
        ok: false,
        status: 422,
      } as Response);

      const client = new ApiClient();
      await expect(client.post('/users', {})).rejects.toThrow('HTTP error! status: 422');
    });
  });

  describe('put', () => {
    it('should make PUT request with data', async () => {
      const mockResponse = { id: 1, name: 'Updated' };
      const putData = { name: 'Updated Name' };

      mockFetch.mockResolvedValue({
        ok: true,
        json: () => Promise.resolve(mockResponse),
      } as Response);

      const client = new ApiClient();
      const result = await client.put('/users/1', putData);

      expect(mockFetch).toHaveBeenCalledWith('/api/users/1', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(putData),
      });
      expect(result).toEqual(mockResponse);
    });
  });

  describe('delete', () => {
    it('should make DELETE request', async () => {
      mockFetch.mockResolvedValue({
        ok: true,
      } as Response);

      const client = new ApiClient();
      await client.delete('/users/1');

      expect(mockFetch).toHaveBeenCalledWith('/api/users/1', {
        method: 'DELETE',
      });
    });

    it('should throw error for non-ok DELETE response', async () => {
      mockFetch.mockResolvedValue({
        ok: false,
        status: 404,
      } as Response);

      const client = new ApiClient();
      await expect(client.delete('/users/1')).rejects.toThrow('HTTP error! status: 404');
    });
  });
});