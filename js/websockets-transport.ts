import { Consumer } from "@rails/actioncable";
import { Transport } from "./application";
import { LiveRenderChannel } from "./cable";
import { RenderRequest } from "./live-component";
import { encode_request } from "./payload";

export class WebSocketsTransport implements Transport {
  public channel: LiveRenderChannel;
  public debug: boolean;

  constructor(consumer: Consumer, debug: boolean = false) {
    this.channel = new LiveRenderChannel(consumer);
    this.debug = debug;
  }

  start() {
    this.channel.start();
  }

  async render(request: RenderRequest): Promise<string> {
    const payload = await encode_request(request);
    return this.channel.render(payload, this.debug);
  }
}
