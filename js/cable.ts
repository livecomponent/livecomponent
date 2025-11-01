// import morphdom from "morphdom"
import type { Consumer, Subscription } from "@rails/actioncable";
import { RenderRequest } from ".";

if (!window.crypto?.randomUUID) {
  /* @ts-ignore */
  window.crypto.randomUUID = function randomUUID() {
    // Prefer secure random values if available
    if (window.crypto && typeof window.crypto.getRandomValues === "function") {
      const bytes = new Uint8Array(16);
      window.crypto.getRandomValues(bytes);

      // Per RFC 4122 v4 UUID format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
      bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant 10

      /* @ts-ignore */
      const hex = [...bytes].map(b => b.toString(16).padStart(2, "0")).join("");
      return (
        hex.slice(0, 8) + "-" +
        hex.slice(8, 12) + "-" +
        hex.slice(12, 16) + "-" +
        hex.slice(16, 20) + "-" +
        hex.slice(20)
      );
    }

    // Fallback if crypto is totally unavailable (less secure)
    const random = () => Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
    return `${random()}${random()}-${random()}-4${random().substr(0, 3)}-a${random().substr(0, 3)}-${random()}${random()}${random()}`;
  };
}

export class LiveRenderChannel {
  private pendingRequests: Map<string, [number, (value: string) => void, () => void]> = new Map();
  private consumer: Consumer;
  private subscription: Promise<Subscription>;

  constructor(consumer: Consumer) {
    this.consumer = consumer;
  }

  start() {
    const channel: LiveRenderChannel = this;

    this.subscription = new Promise<Subscription>(resolve => {
      this.consumer.subscriptions.create(
        {channel: 'LiveComponentChannel'},
        {
          connected() {
            resolve(this);
          },

          received(data) {
            if (channel.pendingRequests.has(data.request_id)) {
              const [startTime, resolveRequest] = channel.pendingRequests.get(data.request_id)!
              const endTime = Date.now();
              const elapsedMs = endTime - startTime;
              // eslint-disable-next-line no-console
              console.log(`Request ${data.request_id} took ${elapsedMs}ms`);
              channel.pendingRequests.delete(data.request_id);
              resolveRequest(data.payload);
            }
          },
        },
      );
    });
  }

  async render(request: RenderRequest): Promise<string> {
    const subscription = await this.subscription;
    const requestId = window.crypto.randomUUID();

    const promise = new Promise<string>((resolve, reject) => {
      this.pendingRequests.set(requestId, [Date.now(), resolve, reject]);
    });

    subscription.send({payload: JSON.stringify(request), request_id: requestId});
    return promise;
  }
}
