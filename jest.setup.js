// Jest setup file
// Add any global test configuration here

// Mock Rails UJS if needed
global.Rails = {
  fire: jest.fn(),
  start: jest.fn(),
  stop: jest.fn()
};

// Setup DOM testing utilities
import { TextEncoder, TextDecoder } from 'util';
global.TextEncoder = TextEncoder;
global.TextDecoder = TextDecoder;