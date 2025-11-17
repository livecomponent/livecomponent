import { vi, beforeEach, afterEach } from "vitest";

// Setup global fetch mock BEFORE importing Turbo
// This ensures Turbo uses our mocked fetch
global.fetch = vi.fn();

import "@hotwired/turbo";

beforeEach(() => {
  // Reset the mock before each test
  vi.mocked(global.fetch).mockReset();
});

afterEach(() => {
  // Clear all mocks after each test
  vi.clearAllMocks();

  document.body.innerHTML = "";
});
