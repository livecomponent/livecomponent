import { HTTPTransport } from "./http-transport";
import { describe, it, expect, vi, beforeEach } from "vitest";
import type { RenderRequest } from "./live-component";
import { encode_payload, encode_request } from "./payload";

describe("HTTPTransport", () => {
  let transport: HTTPTransport;

  beforeEach(() => {
    transport = new HTTPTransport();
  });

  const mock_ok_fetch = async (body: string = "<div>Rendered HTML</div>") => {
    const encoded = await encode_payload(body);

    return vi.fn().mockResolvedValue({
      status: 200,
      text: () => Promise.resolve(encoded),
      headers: {
        get: () => null,
      },
    });
  };

  const example_request = (): RenderRequest => ({
    state: {
      props: { foo: "bar" },
      slots: {},
      children: {},
    },
    reflexes: [],
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

    it("merges static headers from options", async () => {
      const mock_fetch = await mock_ok_fetch();
      global.fetch = mock_fetch;

      const custom = new HTTPTransport("/render", {
        headers: { "X-CSRF-Token": "abc123" },
      });

      await custom.render(example_request());

      expect(mock_fetch.mock.calls[0][1].headers).toStrictEqual({
        "Content-Type": "application/json",
        "Accept": "text/html",
        "X-CSRF-Token": "abc123",
      });
    });

    it("calls a headers function on every request", async () => {
      const mock_fetch = await mock_ok_fetch();
      global.fetch = mock_fetch;

      let token = "first";
      const custom = new HTTPTransport("/render", {
        headers: () => ({ "X-CSRF-Token": token }),
      });

      await custom.render(example_request());
      token = "second";
      await custom.render(example_request());

      expect(mock_fetch.mock.calls[0][1].headers["X-CSRF-Token"]).toBe("first");
      expect(mock_fetch.mock.calls[1][1].headers["X-CSRF-Token"]).toBe("second");
    });

    it("awaits an async headers function", async () => {
      const mock_fetch = await mock_ok_fetch();
      global.fetch = mock_fetch;

      const custom = new HTTPTransport("/render", {
        headers: async () => ({ "X-CSRF-Token": "async-token" }),
      });

      await custom.render(example_request());

      expect(mock_fetch.mock.calls[0][1].headers["X-CSRF-Token"]).toBe("async-token");
    });

    it("passes credentials through when provided", async () => {
      const mock_fetch = await mock_ok_fetch();
      global.fetch = mock_fetch;

      const custom = new HTTPTransport("/render", { credentials: "same-origin" });

      await custom.render(example_request());

      expect(mock_fetch.mock.calls[0][1].credentials).toBe("same-origin");
    });

    it("resolves to an error response when fetch rejects", async () => {
      global.fetch = vi.fn().mockRejectedValue(new Error("network down"));

      const result = await transport.render(example_request());

      expect(result).toMatchObject({
        success: false,
        message: "network down",
        status: "client-error",
      });
    });

    it("resolves to an error response when a headers callback throws", async () => {
      global.fetch = vi.fn();

      const custom = new HTTPTransport("/render", {
        headers: () => { throw new Error("no token"); },
      });

      const result = await custom.render(example_request());

      expect(result).toMatchObject({
        success: false,
        message: "no token",
        status: "client-error",
      });
    });

    it("omits credentials entirely when not provided", async () => {
      const mock_fetch = await mock_ok_fetch();
      global.fetch = mock_fetch;

      await transport.render(example_request());

      expect("credentials" in mock_fetch.mock.calls[0][1]).toBe(false);
    });
  });
});

