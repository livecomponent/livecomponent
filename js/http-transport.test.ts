import { HTTPTransport } from "./http-transport";
import { describe, it, expect, vi, beforeEach } from "vitest";
import type { RenderRequest } from "./live-component";

describe("HTTPTransport", () => {
  let transport: HTTPTransport;

  beforeEach(() => {
    transport = new HTTPTransport();
  });

  describe("constructor", () => {
    it("uses default URL when none provided", () => {
      expect(transport.url).toBe("/live_component/render");
    });

    it("uses custom URL when provided", () => {
      const customTransport = new HTTPTransport("/custom/render");
      expect(customTransport.url).toBe("/custom/render");
    });
  });

  describe("start", () => {
    it("is a no-op", () => {
      expect(() => transport.start()).not.toThrow();
    });
  });

  describe("render", () => {
    it("makes a POST request to the render URL", async () => {
      const mockResponse = "<div>Rendered HTML</div>";
      const mockFetch = vi.fn().mockResolvedValue({
        text: () => Promise.resolve(mockResponse),
      });

      global.fetch = mockFetch;

      const request: RenderRequest = {
        state: {
          props: { foo: "bar" },
          slots: {},
          children: {},
        },
        reflexes: [],
      };

      const result = await transport.render(request);

      expect(mockFetch).toHaveBeenCalledWith("/live_component/render", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "text/html",
        },
        body: JSON.stringify({ payload: JSON.stringify(request) }),
      });

      expect(result).toBe(mockResponse);
    });
  });
});

