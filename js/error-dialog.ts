import { ErrorResponse } from "./live-component";

export const render_error_dialog = (response: ErrorResponse) => {
  const message = response.message ?? "An error occurred";
  const show_backtrace_label = Boolean(response.backtrace);
  const body = response.backtrace
    ? response.backtrace.map(t => `<span class="lc-error-dialog-backtrace-line">${t}</span>`).join("")
    : response.body;

  return `
    <div class="lc-error-dialog-wrapper">
      <style>
        .lc-error-dialog {
          width: 75%;
          border-radius: 10px;
          filter: drop-shadow(0px 0px 10px #828282);
          border: 0;
          padding: 0;
          font-family: monospace;
          overflow: hidden;
        }

        @media (prefers-color-scheme: dark) {
          .lc-error-dialog {
            background-color: #000;
          }

          .lc-error-dialog-backtrace {
            color: #FFF;
          }
        }

        @media (prefers-color-scheme: light) {
          .lc-error-dialog {
            background-color: #FFF;
          }

          .lc-error-dialog-backtrace {
            color: #000;
          }
        }

        .lc-error-dialog-header {
          padding: 20px;
          background-color: #623999;
          color: #FFF;
          font-size: 18px;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }

        .lc-error-dialog-backtrace {
          padding: 20px;
          overflow: auto;
          max-height: 60vh;
        }

        .lc-error-dialog-backtrace-lines {
          display: flex;
          flex-direction: column;
          gap: 0.7em;
          padding: 20px;
        }

        .lc-error-dialog-backtrace-line {
          display: inline-block;
          text-indent: -2em;
          padding-left: 2em;
        }

        .lc-error-dismiss-btn {
          border-radius: 5px;
          background-color: transparent;
          border: 1px solid transparent;
          fill: #FFF;
          display: flex;
          align-items: center;
          justify-content: center;
          height: 32px;
          width: 32px;
        }

        .lc-error-dismiss-btn:hover {
          border: 1px solid #CCC;
        }
      </style>
      <dialog closedby="any" class="lc-error-dialog">
        <div class="lc-error-dialog-header">
          <div>
            <div style="font-size: 14px; padding-bottom: 5px">An error occurred during LiveComponent rendering</div>
            <div>${message}</div>
          </div>
          <button class="lc-error-dismiss-btn" onclick="event.target.closest('.lc-error-dialog-wrapper').remove()">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24"><path d="M5.72 5.72a.75.75 0 0 1 1.06 0L12 10.94l5.22-5.22a.749.749 0 0 1 1.275.326.749.749 0 0 1-.215.734L13.06 12l5.22 5.22a.749.749 0 0 1-.326 1.275.749.749 0 0 1-.734-.215L12 13.06l-5.22 5.22a.751.751 0 0 1-1.042-.018.751.751 0 0 1-.018-1.042L10.94 12 5.72 6.78a.75.75 0 0 1 0-1.06Z"></path></svg>
          </button>
        </div>
        <div class="lc-error-dialog-backtrace">
          ${show_backtrace_label
            ?
              `<div>Backtrace:</div>
              <div class="lc-error-dialog-backtrace-lines">
                ${body}
              </div>`
            : body
          }
        </div>
      </dialog>
    </div>
  `;
}
