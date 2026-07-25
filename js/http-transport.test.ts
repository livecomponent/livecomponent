import { HTTPTransport } from "./http-transport";
import { describe, it, expect, vi, beforeEach } from "vitest";
import type { RenderRequest } from "./live-component";
import { encode_payload, encode_request } from "./payload";

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
      const mock_response = "<div>Rendered HTML</div>";
      const encoded_mock_response = await encode_payload(mock_response);
      const mock_fetch = vi.fn().mockResolvedValue({
        status: 200,
        text: () => Promise.resolve(encoded_mock_response),
        headers: {
          get: () => null,
        },
      });

      global.fetch = mock_fetch;

      const request: RenderRequest = {
        state: {
          props: { foo: "bar" },
          slots: {},
          children: {},
        },
        reflexes: [],
      };

      const result = await transport.render(request);
      const payload = await encode_request(request);

      expect(mock_fetch).toHaveBeenCalledWith("/live_component/render", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "text/html",
        },
        body: JSON.stringify({payload}),
      });

      expect(result).toStrictEqual({
        success: true,
        body: mock_response,
      });
    });
  });
});

