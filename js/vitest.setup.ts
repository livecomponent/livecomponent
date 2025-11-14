import { vi, beforeEach, afterEach } from "vitest";

// Setup global fetch mock
beforeEach(() => {
  // Create a mock fetch function that can be customized per test
  global.fetch = vi.fn();
});

afterEach(() => {
  // Clear all mocks after each test
  vi.clearAllMocks();

  document.body.innerHTML = "";
});
