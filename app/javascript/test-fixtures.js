// Database fixtures and mocks for enhanced JavaScript testing capabilities
// This provides database-like functionality for testing components that interact with the backend

export class DatabaseFixtures {
  constructor() {
    this.data = {
      users: [
        {
          id: 1,
          email: 'test@example.com',
          name: 'Test User',
          organization_id: 1
        },
        {
          id: 2,
          email: 'admin@example.com',
          name: 'Admin User',
          organization_id: 1
        }
      ],
      organizations: [
        {
          id: 1,
          name: 'Test Organization',
          created_at: '2024-01-01T00:00:00.000Z'
        }
      ],
      test_cases: [
        {
          id: 1,
          title: 'Sample Test Case',
          description: 'A test case for testing',
          steps: ['Step 1', 'Step 2', 'Step 3'],
          organization_id: 1
        }
      ],
      test_results: [
        {
          id: 1,
          test_case_id: 1,
          status: 'passed',
          executed_at: '2024-01-01T12:00:00.000Z'
        }
      ]
    };
  }

  // Get all records from a table
  findAll(tableName) {
    return this.data[tableName] || [];
  }

  // Find a specific record by ID
  find(tableName, id) {
    const table = this.data[tableName] || [];
    return table.find(record => record.id === id);
  }

  // Find records matching criteria
  findWhere(tableName, criteria) {
    const table = this.data[tableName] || [];
    return table.filter(record => {
      return Object.keys(criteria).every(key => record[key] === criteria[key]);
    });
  }

  // Create a new record
  create(tableName, attributes) {
    const table = this.data[tableName] || [];
    const newId = Math.max(...table.map(r => r.id), 0) + 1;
    const record = { id: newId, ...attributes };
    table.push(record);
    return record;
  }

  // Update a record
  update(tableName, id, attributes) {
    const table = this.data[tableName] || [];
    const index = table.findIndex(record => record.id === id);
    if (index !== -1) {
      table[index] = { ...table[index], ...attributes };
      return table[index];
    }
    return null;
  }

  // Delete a record
  destroy(tableName, id) {
    const table = this.data[tableName] || [];
    const index = table.findIndex(record => record.id === id);
    if (index !== -1) {
      return table.splice(index, 1)[0];
    }
    return null;
  }

  // Reset fixtures to initial state
  reset() {
    this.data = {
      users: [
        {
          id: 1,
          email: 'test@example.com',
          name: 'Test User',
          organization_id: 1
        },
        {
          id: 2,
          email: 'admin@example.com',
          name: 'Admin User',
          organization_id: 1
        }
      ],
      organizations: [
        {
          id: 1,
          name: 'Test Organization',
          created_at: '2024-01-01T00:00:00.000Z'
        }
      ],
      test_cases: [
        {
          id: 1,
          title: 'Sample Test Case',
          description: 'A test case for testing',
          steps: ['Step 1', 'Step 2', 'Step 3'],
          organization_id: 1
        }
      ],
      test_results: [
        {
          id: 1,
          test_case_id: 1,
          status: 'passed',
          executed_at: '2024-01-01T12:00:00.000Z'
        }
      ]
    };
  }
}

// Mock API client that works with fixtures
export class MockApiClient {
  constructor(fixtures) {
    this.fixtures = fixtures;
  }

  // GET /api/resource
  async get(endpoint) {
    const [, tableName] = endpoint.split('/').filter(Boolean);
    return {
      status: 200,
      data: this.fixtures.findAll(tableName)
    };
  }

  // GET /api/resource/:id
  async getById(endpoint, id) {
    const [, tableName] = endpoint.split('/').filter(Boolean);
    const record = this.fixtures.find(tableName, id);
    
    if (record) {
      return { status: 200, data: record };
    } else {
      return { status: 404, error: 'Not found' };
    }
  }

  // POST /api/resource
  async post(endpoint, data) {
    const [, tableName] = endpoint.split('/').filter(Boolean);
    const record = this.fixtures.create(tableName, data);
    return { status: 201, data: record };
  }

  // PUT /api/resource/:id
  async put(endpoint, id, data) {
    const [, tableName] = endpoint.split('/').filter(Boolean);
    const record = this.fixtures.update(tableName, id, data);
    
    if (record) {
      return { status: 200, data: record };
    } else {
      return { status: 404, error: 'Not found' };
    }
  }

  // DELETE /api/resource/:id
  async delete(endpoint, id) {
    const [, tableName] = endpoint.split('/').filter(Boolean);
    const record = this.fixtures.destroy(tableName, id);
    
    if (record) {
      return { status: 204 };
    } else {
      return { status: 404, error: 'Not found' };
    }
  }
}

// Global fixtures instance for tests
export const fixtures = new DatabaseFixtures();
export const mockApiClient = new MockApiClient(fixtures);