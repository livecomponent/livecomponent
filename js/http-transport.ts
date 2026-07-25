import { decode_response, encode_request } from "./payload";
import { Transport } from "./application";
import { RenderRequest, RenderResponse, ErrorResponseStatus } from "./live-component";

export class HTTPTransport implements Transport {
  public url: string;

  constructor(url: string = "/live_component/render") {
    this.url = url;
  }

  start() {
    // no-op
  }

  async render(request: RenderRequest): Promise<RenderResponse> {
    try {
      return this.render_request(request);
    } catch (e) {
      return {
        success: false,
        body: e.stack,
        message: e.message,
        backtrace: e.stack,
        status: "client-error",
      }
    }
  }

  private async render_request(request: RenderRequest): Promise<RenderResponse> {
    const payload = await encode_request(request);

    const response = await fetch(this.url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "text/html"
      },
      body: JSON.stringify({payload})
    });

    const error_status = this.code_to_error_status(response.status);
    const body = await response.text();

    if (error_status) {
      const message = response.headers.get("X-Live-Error-Message");
      const backtrace_str = response.headers.get("X-Live-Error-Backtrace-Json");
      const backtrace = backtrace_str ? JSON.parse(backtrace_str) : undefined;

      return {
        success: false,
        body,
        message,
        backtrace,
        status: error_status
      };
    } else {
      const decoded_body = await decode_response(body);

      return {
        success: true,
        body: decoded_body,
      };
    }
  }

  private code_to_error_status(code: number): ErrorResponseStatus | "unknown" | undefined {
    switch (Math.floor(code / 100)) {
      case 5:
        return "server-error";
      case 4:
        return "client-error";
      case 2:
      case 3:
        return undefined;
      default:
        return "unknown";
    }
  }
}
