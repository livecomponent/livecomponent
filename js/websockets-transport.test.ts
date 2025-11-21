import { WebSocketsTransport } from "./websockets-transport";
import { describe, it, expect, vi, beforeEach } from "vitest";
import type { RenderRequest } from "./live-component";
import type { Consumer, Subscription } from "@rails/actioncable";
import { encode, encode_request } from "./payload";

describe("WebSocketsTransport", () => {
  let transport: WebSocketsTransport;
  let mock_consumer: Consumer;
  let mock_subscription: Subscription;
  let connected_callback: (() => void) | null = null;
  let received_callback: ((data: any) => void) | null = null;

  beforeEach(() => {
    connected_callback = null;
    received_callback = null;

    // Create a mock subscription
    mock_subscription = {
      send: vi.fn(),
      unsubscribe: vi.fn(),
      perform: vi.fn(),
    } as unknown as Subscription;

    // Create a mock consumer with subscriptions.create
    mock_consumer = {
      subscriptions: {
        create: vi.fn((_channel, callbacks) => {
          // Store the callbacks for later use
          connected_callback = callbacks.connected?.bind(mock_subscription);
          received_callback = callbacks.received?.bind(mock_subscription);
          return mock_subscription;
        }),
      },
    } as unknown as Consumer;

    transport = new WebSocketsTransport(mock_consumer);
  });

  describe("constructor", () => {
    it("creates a LiveRenderChannel with the consumer", () => {
      expect(transport.channel).toBeDefined();
      expect(transport.channel.constructor.name).toBe("LiveRenderChannel");
    });
  });

  describe("start", () => {
    it("starts the channel", () => {
      const start_spy = vi.spyOn(transport.channel, "start");
      transport.start();
      expect(start_spy).toHaveBeenCalled();
    });

    it("creates a subscription to LiveComponentChannel", () => {
      transport.start();
      expect(mock_consumer.subscriptions.create).toHaveBeenCalledWith(
        { channel: "LiveComponentChannel" },
        expect.objectContaining({
          connected: expect.any(Function),
          received: expect.any(Function),
        })
      );
    });
  });

  describe("render", () => {
    it("sends a render request through the channel", async () => {
      const request: RenderRequest = {
        state: {
          props: { foo: "bar" },
          slots: {},
          children: {},
        },
        reflexes: [],
      };

      // Start the channel first to establish the subscription
      transport.start();

      // Simulate the connection being established
      if (connected_callback) {
        connected_callback();
      }

      // Wait a tick for the subscription promise to resolve
      await new Promise((resolve) => setTimeout(resolve, 0));

      // Create a promise that will be resolved when we simulate the response
      const render_promise = transport.render(request);
      const payload = await encode_request(request);

      // Wait a tick for the send to be called
      await new Promise((resolve) => setTimeout(resolve, 0));

      // Get the request_id that was sent
      expect(mock_subscription.send).toHaveBeenCalledWith(
        expect.objectContaining({
          payload,
          request_id: expect.any(String),
        })
      );

      // Simulate receiving a response from the server
      const sent_call = (mock_subscription.send as any).mock.calls[0][0];
      const request_id = sent_call.request_id;

      // Simulate the server response
      const mock_response = "<div>Rendered HTML</div>";
      const encoded_mock_response = await encode(mock_response);
      if (received_callback) {
        received_callback({
          request_id: request_id,
          payload: encoded_mock_response,
        });
      }

      // Wait for the promise to resolve
      const result = await render_promise;

      expect(result).toBe(mock_response);
    });

    it("handles multiple concurrent requests", async () => {
      const request1: RenderRequest = {
        state: { props: { id: 1 }, slots: {}, children: {} },
        reflexes: [],
      };

      const request2: RenderRequest = {
        state: { props: { id: 2 }, slots: {}, children: {} },
        reflexes: [],
      };

      // Start the channel
      transport.start();

      // Simulate the connection being established
      if (connected_callback) {
        connected_callback();
      }

      // Wait for the subscription promise to resolve
      await new Promise((resolve) => setTimeout(resolve, 0));

      // Send both requests
      const promise1 = transport.render(request1);
      const promise2 = transport.render(request2);

      // Wait for both sends to be called (need to wait longer for async encoding)
      await new Promise((resolve) => setTimeout(resolve, 100));

      // Get the request IDs
      const calls = (mock_subscription.send as any).mock.calls;
      const request_id1 = calls[0][0].request_id;
      const request_id2 = calls[1][0].request_id;

      // Encode the responses
      const response1 = "<div>Response 1</div>";
      const response2 = "<div>Response 2</div>";
      const encoded_response1 = await encode(response1);
      const encoded_response2 = await encode(response2);

      // Respond to request 2 first (out of order)
      if (received_callback) {
        received_callback({
          request_id: request_id2,
          payload: encoded_response2,
        });
      }

      // Respond to request 1
      if (received_callback) {
        received_callback({
          request_id: request_id1,
          payload: encoded_response1,
        });
      }

      // Both promises should resolve with the correct responses
      expect(await promise1).toBe(response1);
      expect(await promise2).toBe(response2);
    });
  });
});

