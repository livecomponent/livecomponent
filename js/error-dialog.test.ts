import { describe, it, expect, afterEach } from "vitest";
import { show_error_dialog } from "./error-dialog";
import { ErrorResponse } from "./live-component";

describe("show_error_dialog", () => {
  afterEach(() => {
    document.body.innerHTML = "";
  });

  const make_response = (overrides: Partial<ErrorResponse> = {}): ErrorResponse => ({
    success: false,
    status: "server-error",
    body: "",
    message: null,
    ...overrides,
  });

  it("renders the message and backtrace lines as text, not markup", () => {
    const payload = `<img src=x onerror="document.body.dataset.pwned = '1'">`;

    show_error_dialog(make_response({
      message: `Boom ${payload}`,
      backtrace: [`app/models/user.rb:1 ${payload}`, "<b>second</b>"],
    }));

    const dialog = document.querySelector(".lc-error-dialog")!;
    expect(dialog.querySelector("img")).toBeNull();
    expect(dialog.querySelector("b")).toBeNull();
    expect(document.body.dataset.pwned).toBeUndefined();

    expect(dialog.querySelector(".lc-error-dialog-header")!.textContent).toContain(`Boom ${payload}`);

    const lines = dialog.querySelectorAll(".lc-error-dialog-backtrace-line");
    expect(lines).toHaveLength(2);
    expect(lines[0].textContent).toBe(`app/models/user.rb:1 ${payload}`);
    expect(lines[1].textContent).toBe("<b>second</b>");
  });

  it("renders the body as text when there is no backtrace", () => {
    show_error_dialog(make_response({ body: `<script>window.pwned = true</script>` }));

    const dialog = document.querySelector(".lc-error-dialog")!;
    expect(dialog.querySelector("script")).toBeNull();
    expect((window as any).pwned).toBeUndefined();
    expect(dialog.querySelector(".lc-error-dialog-backtrace")!.textContent).toContain("<script>window.pwned = true</script>");
  });

  it("falls back to a default message", () => {
    show_error_dialog(make_response({ message: null, body: "details" }));

    expect(document.querySelector(".lc-error-dialog-header")!.textContent).toContain("An error occurred");
  });
});
