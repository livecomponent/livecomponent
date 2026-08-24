import { describe, it, expect, afterEach, vi } from "vitest";
import { Application as StimulusApplication } from "@hotwired/stimulus";
import { Application } from "./application";
import { default_error_dialog_enabled, report_error, set_error_dialog_enabled } from "./error";
import { ErrorResponse } from "./live-component";

const make_error_response = (): ErrorResponse => ({
  success: false,
  status: "server-error",
  body: "<pre>boom</pre>",
  message: "boom",
});

const make_target = () => {
  const target = document.createElement("div");
  document.body.appendChild(target);
  return target;
};

describe("error dialog gating", () => {
  afterEach(() => {
    vi.unstubAllEnvs();
    vi.restoreAllMocks();
    set_error_dialog_enabled(default_error_dialog_enabled());
  });

  describe("default_error_dialog_enabled", () => {
    it("is enabled outside production", () => {
      vi.stubEnv("NODE_ENV", "development");
      expect(default_error_dialog_enabled()).toBe(true);
    });

    it("is disabled in production", () => {
      vi.stubEnv("NODE_ENV", "production");
      expect(default_error_dialog_enabled()).toBe(false);
    });
  });

  describe("report_error", () => {
    it("shows the error dialog when enabled", () => {
      set_error_dialog_enabled(true);

      report_error(make_target(), make_error_response());

      expect(document.querySelector(".lc-error-dialog")).not.toBeNull();
    });

    it("logs to console.error instead of showing the dialog when disabled", () => {
      set_error_dialog_enabled(false);
      const console_error = vi.spyOn(console, "error").mockImplementation(() => {});
      const response = make_error_response();

      report_error(make_target(), response);

      expect(document.querySelector(".lc-error-dialog")).toBeNull();
      expect(console_error).toHaveBeenCalledWith(expect.any(String), response);
    });

    it("still dispatches livecomponent:error when disabled", () => {
      set_error_dialog_enabled(false);
      vi.spyOn(console, "error").mockImplementation(() => {});
      const target = make_target();
      const response = make_error_response();

      const events: CustomEvent[] = [];
      target.addEventListener("livecomponent:error", (e: Event) => events.push(e as CustomEvent));

      report_error(target, response);

      expect(events).toHaveLength(1);
      expect(events[0].detail).toBe(response);
    });

    it("does not log when a listener prevents the default", () => {
      set_error_dialog_enabled(false);
      const console_error = vi.spyOn(console, "error").mockImplementation(() => {});
      const target = make_target();
      target.addEventListener("livecomponent:error", (e: Event) => e.preventDefault());

      report_error(target, make_error_response());

      expect(console_error).not.toHaveBeenCalled();
    });
  });

  describe("Application.start", () => {
    it("disables the error dialog via the error_dialog option", () => {
      const transport = { start: vi.fn(), render: vi.fn() };
      vi.spyOn(console, "error").mockImplementation(() => {});

      Application.start(StimulusApplication.start(), transport, { error_dialog: false });

      report_error(make_target(), make_error_response());

      expect(document.querySelector(".lc-error-dialog")).toBeNull();
    });
  });
});
