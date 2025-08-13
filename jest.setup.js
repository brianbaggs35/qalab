// Jest setup file
// Add any global test configuration here

// Import database fixtures for enhanced testing
import { fixtures, mockApiClient } from './app/javascript/test-fixtures.js';

// Mock Rails UJS if needed
global.Rails = {
  fire: jest.fn(),
  start: jest.fn(),
  stop: jest.fn()
};

// Setup DOM testing utilities
const { TextEncoder, TextDecoder } = require('util');
global.TextEncoder = TextEncoder;
global.TextDecoder = TextDecoder;

// Make database fixtures available globally in tests
global.fixtures = fixtures;
global.mockApiClient = mockApiClient;

// Reset fixtures before each test
beforeEach(() => {
  fixtures.reset();
});

// Mock fetch for API calls in tests
global.fetch = jest.fn();