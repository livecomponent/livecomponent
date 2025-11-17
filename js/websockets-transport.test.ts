import { WebSocketsTransport } from "./websockets-transport";
import { describe, it, expect, vi, beforeEach } from "vitest";
import type { RenderRequest } from "./live-component";
import type { Consumer, Subscription } from "@rails/actioncable";

describe("WebSocketsTransport", () => {
  let transport: WebSocketsTransport;
  let mockConsumer: Consumer;
  let mockSubscription: Subscription;
  let connectedCallback: (() => void) | null = null;
  let receivedCallback: ((data: any) => void) | null = null;

  beforeEach(() => {
    connectedCallback = null;
    receivedCallback = null;

    // Create a mock subscription
    mockSubscription = {
      send: vi.fn(),
      unsubscribe: vi.fn(),
      perform: vi.fn(),
    } as unknown as Subscription;

    // Create a mock consumer with subscriptions.create
    mockConsumer = {
      subscriptions: {
        create: vi.fn((_channel, callbacks) => {
          // Store the callbacks for later use
          connectedCallback = callbacks.connected?.bind(mockSubscription);
          receivedCallback = callbacks.received?.bind(mockSubscription);
          return mockSubscription;
        }),
      },
    } as unknown as Consumer;

    transport = new WebSocketsTransport(mockConsumer);
  });

  describe("constructor", () => {
    it("creates a LiveRenderChannel with the consumer", () => {
      expect(transport.channel).toBeDefined();
      expect(transport.channel.constructor.name).toBe("LiveRenderChannel");
    });
  });

  describe("start", () => {
    it("starts the channel", () => {
      const startSpy = vi.spyOn(transport.channel, "start");
      transport.start();
      expect(startSpy).toHaveBeenCalled();
    });

    it("creates a subscription to LiveComponentChannel", () => {
      transport.start();
      expect(mockConsumer.subscriptions.create).toHaveBeenCalledWith(
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
      if (connectedCallback) {
        connectedCallback();
      }

      // Wait a tick for the subscription promise to resolve
      await new Promise((resolve) => setTimeout(resolve, 0));

      // Create a promise that will be resolved when we simulate the response
      const renderPromise = transport.render(request);

      // Wait a tick for the send to be called
      await new Promise((resolve) => setTimeout(resolve, 0));

      // Get the request_id that was sent
      expect(mockSubscription.send).toHaveBeenCalledWith(
        expect.objectContaining({
          payload: JSON.stringify(request),
          request_id: expect.any(String),
        })
      );

      // Simulate receiving a response from the server
      const sentCall = (mockSubscription.send as any).mock.calls[0][0];
      const requestId = sentCall.request_id;

      // Simulate the server response
      const mockResponse = "<div>Rendered HTML</div>";
      if (receivedCallback) {
        receivedCallback({
          request_id: requestId,
          payload: mockResponse,
        });
      }

      // Wait for the promise to resolve
      const result = await renderPromise;

      expect(result).toBe(mockResponse);
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
      if (connectedCallback) {
        connectedCallback();
      }

      // Wait for the subscription promise to resolve
      await new Promise((resolve) => setTimeout(resolve, 0));

      // Send both requests
      const promise1 = transport.render(request1);
      const promise2 = transport.render(request2);

      // Wait for both sends to be called
      await new Promise((resolve) => setTimeout(resolve, 0));

      // Get the request IDs
      const calls = (mockSubscription.send as any).mock.calls;
      const requestId1 = calls[0][0].request_id;
      const requestId2 = calls[1][0].request_id;

      // Respond to request 2 first (out of order)
      if (receivedCallback) {
        receivedCallback({
          request_id: requestId2,
          payload: "<div>Response 2</div>",
        });
      }

      // Respond to request 1
      if (receivedCallback) {
        receivedCallback({
          request_id: requestId1,
          payload: "<div>Response 1</div>",
        });
      }

      // Both promises should resolve with the correct responses
      expect(await promise1).toBe("<div>Response 1</div>");
      expect(await promise2).toBe("<div>Response 2</div>");
    });
  });
});

