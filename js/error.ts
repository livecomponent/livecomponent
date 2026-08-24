import type { ErrorResponse } from "./live-component";
import { show_error_dialog } from "./error-dialog";

export const ERROR_EVENT_NAME = "livecomponent:error";

export type LiveComponentErrorEvent = CustomEvent<ErrorResponse>;

export const report_error = (target: Element, response: ErrorResponse) => {
  const event: LiveComponentErrorEvent = new CustomEvent(ERROR_EVENT_NAME, {
    detail: response,
    cancelable: true,
    bubbles: true,
  });

  target.dispatchEvent(event);

  if (!event.defaultPrevented) show_error_dialog(response);
};

declare global {
  interface HTMLElementEventMap {
    "livecomponent:error": LiveComponentErrorEvent;
  }

  interface DocumentEventMap {
    "livecomponent:error": LiveComponentErrorEvent;
  }
}
