import type { ErrorResponse } from "./live-component";
import { show_error_dialog } from "./error-dialog";

export const ERROR_EVENT_NAME = "livecomponent:error";

export type LiveComponentErrorEvent = CustomEvent<ErrorResponse>;

declare const process: { env: Record<string, string | undefined> };

// Bundlers replace `process.env.NODE_ENV` statically; unbundled, `process` is
// undefined and the access throws.
export const default_error_dialog_enabled = (): boolean => {
  try {
    return process.env.NODE_ENV !== "production";
  } catch {
    return true;
  }
};

let error_dialog_enabled = default_error_dialog_enabled();

export const set_error_dialog_enabled = (enabled: boolean) => {
  error_dialog_enabled = enabled;
};

export const report_error = (target: Element, response: ErrorResponse) => {
  const event: LiveComponentErrorEvent = new CustomEvent(ERROR_EVENT_NAME, {
    detail: response,
    cancelable: true,
    bubbles: true,
  });

  target.dispatchEvent(event);

  if (event.defaultPrevented) return;

  if (error_dialog_enabled) {
    show_error_dialog(response);
  } else {
    console.error("An error occurred during LiveComponent rendering", response);
  }
};

declare global {
  interface HTMLElementEventMap {
    "livecomponent:error": LiveComponentErrorEvent;
  }

  interface DocumentEventMap {
    "livecomponent:error": LiveComponentErrorEvent;
  }
}
