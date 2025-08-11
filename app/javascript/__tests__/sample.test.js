// Sample Jest test to ensure Jest is working properly
describe('Sample Test Suite', () => {
  test('should pass a basic test', () => {
    expect(1 + 1).toBe(2);
  });

  test('should have Rails globals available', () => {
    expect(global.Rails).toBeDefined();
    expect(typeof global.Rails.fire).toBe('function');
  });
});