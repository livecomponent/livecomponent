import { decode, encode_request } from "./payload";
import { Transport } from "./application";
import { RenderRequest, RenderResponse, ErrorResponseStatus } from "./live-component";

export type HTTPTransportHeaders =
  | Record<string, string>
  | (() => Record<string, string> | Promise<Record<string, string>>);

export interface HTTPTransportOptions {
  // Extra headers merged over the defaults on every request. Pass a function
  // when the value can change during the page's lifetime — a Rails CSRF
  // token, for example, is replaced on Turbo navigation.
  headers?: HTTPTransportHeaders;

  // Forwarded to fetch(). Needed when the render endpoint is a real
  // controller behind session authentication rather than the Rack
  // middleware, which requires no cookies.
  credentials?: RequestCredentials;
}

export class HTTPTransport implements Transport {
  public url: string;
  private options: HTTPTransportOptions;

  constructor(url: string = "/live_component/render", options: HTTPTransportOptions = {}) {
    this.url = url;
    this.options = options;
  }

  start() {
    // no-op
  }

  async render(request: RenderRequest): Promise<RenderResponse> {
    try {
      // `await` is load-bearing: without it the promise settles after the
      // try block has exited, so an async rejection -- from a headers
      // callback, encode_request, or fetch itself -- escapes this handler
      // and render() rejects instead of resolving to an error response.
      return await this.render_request(request);
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
        "Accept": "text/html",
        ...(await this.extra_headers())
      },
      ...(this.options.credentials ? { credentials: this.options.credentials } : {}),
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
      const decoded_body = await decode(body);

      return {
        success: true,
        body: decoded_body,
      };
    }
  }

  private async extra_headers(): Promise<Record<string, string>> {
    const { headers } = this.options;
    if (!headers) return {};

    return typeof headers === "function" ? await headers() : headers;
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
