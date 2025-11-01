import { Consumer } from "@rails/actioncable";
import { Transport } from "./application";
import { LiveRenderChannel } from "./cable";
import { RenderRequest } from "./live-component";

export class WebSocketsTransport implements Transport {
  public channel: LiveRenderChannel;

  constructor(consumer: Consumer) {
    this.channel = new LiveRenderChannel(consumer);
  }

  start() {
    this.channel.start();
  }

  async render(request: RenderRequest): Promise<string> {
    return this.channel.render(request);
  }
}
