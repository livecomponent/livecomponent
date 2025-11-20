import { encode_request } from "./payload";
import { Transport } from "./application";
import { RenderRequest } from "./live-component";

export class HTTPTransport implements Transport {
  public url: string;

  constructor(url: string = "/live_component/render") {
    this.url = url;
  }

  start() {
    // no-op
  }

  async render(request: RenderRequest): Promise<string> {
    const payload = await encode_request(request);

    return fetch(this.url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "text/html"
      },
      body: JSON.stringify({payload})
    }).then(response => response.text());
  }
}
