/**
 * @jest-environment jsdom
 */

import { fixtures, mockApiClient } from "../test-fixtures";

describe("Database Fixtures Integration", () => {
  describe("DatabaseFixtures", () => {
    it("should provide sample data for testing", () => {
      const users = fixtures.findAll('users');
      expect(users).toHaveLength(2);
      expect(users[0]).toMatchObject({
        id: 1,
        email: 'test@example.com',
        name: 'Test User'
      });
    });

    it("should allow creating new records", () => {
      const newUser = fixtures.create('users', {
        email: 'new@example.com',
        name: 'New User',
        organization_id: 1
      });

      expect(newUser).toMatchObject({
        id: 3,
        email: 'new@example.com',
        name: 'New User'
      });

      const users = fixtures.findAll('users');
      expect(users).toHaveLength(3);
    });

    it("should allow updating records", () => {
      const updated = fixtures.update('users', 1, {
        name: 'Updated Name'
      });

      expect(updated).toMatchObject({
        id: 1,
        email: 'test@example.com',
        name: 'Updated Name'
      });
    });

    it("should allow deleting records", () => {
      const deleted = fixtures.destroy('users', 1);
      expect(deleted).toMatchObject({
        id: 1,
        email: 'test@example.com'
      });

      const users = fixtures.findAll('users');
      expect(users).toHaveLength(1);
    });

    it("should reset data between tests", () => {
      // This test verifies that the beforeEach hook resets the data
      const users = fixtures.findAll('users');
      expect(users).toHaveLength(2); // Should be reset to original state
    });

    it("should support finding records by criteria", () => {
      const orgUsers = fixtures.findWhere('users', { organization_id: 1 });
      expect(orgUsers).toHaveLength(2);

      const testUser = fixtures.findWhere('users', { email: 'test@example.com' });
      expect(testUser).toHaveLength(1);
      expect(testUser[0].name).toBe('Test User');
    });
  });

  describe("MockApiClient", () => {
    it("should mock GET requests", async () => {
      const response = await mockApiClient.get('/api/users');
      
      expect(response.status).toBe(200);
      expect(response.data).toHaveLength(2);
    });

    it("should mock GET by ID requests", async () => {
      const response = await mockApiClient.getById('/api/users', 1);
      
      expect(response.status).toBe(200);
      expect(response.data).toMatchObject({
        id: 1,
        email: 'test@example.com'
      });
    });

    it("should return 404 for non-existent records", async () => {
      const response = await mockApiClient.getById('/api/users', 999);
      
      expect(response.status).toBe(404);
      expect(response.error).toBe('Not found');
    });

    it("should mock POST requests", async () => {
      const newUser = {
        email: 'created@example.com',
        name: 'Created User',
        organization_id: 1
      };

      const response = await mockApiClient.post('/api/users', newUser);
      
      expect(response.status).toBe(201);
      expect(response.data).toMatchObject({
        id: 3,
        email: 'created@example.com',
        name: 'Created User'
      });
    });

    it("should mock PUT requests", async () => {
      const updates = { name: 'Updated Name' };
      const response = await mockApiClient.put('/api/users', 1, updates);
      
      expect(response.status).toBe(200);
      expect(response.data).toMatchObject({
        id: 1,
        name: 'Updated Name'
      });
    });

    it("should mock DELETE requests", async () => {
      const response = await mockApiClient.delete('/api/users', 1);
      
      expect(response.status).toBe(204);
      
      // Verify the record was deleted
      const getResponse = await mockApiClient.getById('/api/users', 1);
      expect(getResponse.status).toBe(404);
    });
  });

  describe("Test data relationships", () => {
    it("should provide related test cases and results", () => {
      const testCases = fixtures.findAll('test_cases');
      const testResults = fixtures.findAll('test_results');
      
      expect(testCases).toHaveLength(1);
      expect(testResults).toHaveLength(1);
      
      const testCase = testCases[0];
      const relatedResults = fixtures.findWhere('test_results', { 
        test_case_id: testCase.id 
      });
      
      expect(relatedResults).toHaveLength(1);
      expect(relatedResults[0].status).toBe('passed');
    });

    it("should support organization-scoped data", () => {
      const orgUsers = fixtures.findWhere('users', { organization_id: 1 });
      const orgTestCases = fixtures.findWhere('test_cases', { organization_id: 1 });
      
      expect(orgUsers).toHaveLength(2);
      expect(orgTestCases).toHaveLength(1);
    });
  });

  describe("Enhanced testing scenarios", () => {
    it("should enable complex test scenarios with data", () => {
      // Create a test scenario: user creates a test case
      const user = fixtures.find('users', 1);
      expect(user).toBeDefined();

      const newTestCase = fixtures.create('test_cases', {
        title: 'New Test Case',
        description: 'Created by user',
        steps: ['Setup', 'Execute', 'Verify'],
        organization_id: user.organization_id
      });

      // Create test results for this test case
      const testResult = fixtures.create('test_results', {
        test_case_id: newTestCase.id,
        status: 'failed',
        executed_at: new Date().toISOString()
      });

      // Verify the relationships
      const userTestCases = fixtures.findWhere('test_cases', { 
        organization_id: user.organization_id 
      });
      expect(userTestCases).toHaveLength(2);

      const caseResults = fixtures.findWhere('test_results', { 
        test_case_id: newTestCase.id 
      });
      expect(caseResults).toHaveLength(1);
      expect(caseResults[0].status).toBe('failed');
    });

    it("should support testing workflow states", () => {
      // Test a workflow: create test case → run test → update results
      const testCase = fixtures.create('test_cases', {
        title: 'Workflow Test',
        description: 'Testing workflow',
        steps: ['Step 1', 'Step 2'],
        organization_id: 1
      });

      // Initially no results
      let results = fixtures.findWhere('test_results', { 
        test_case_id: testCase.id 
      });
      expect(results).toHaveLength(0);

      // Execute test
      const testResult = fixtures.create('test_results', {
        test_case_id: testCase.id,
        status: 'running',
        executed_at: new Date().toISOString()
      });

      // Update result
      const updatedResult = fixtures.update('test_results', testResult.id, {
        status: 'passed'
      });

      expect(updatedResult.status).toBe('passed');
      expect(updatedResult.test_case_id).toBe(testCase.id);
    });
  });
});