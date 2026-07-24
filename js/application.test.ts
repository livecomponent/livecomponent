import { describe, it, expect, beforeAll, vi } from "vitest";
import { TestContext, testSetup } from "./test-helpers/setup";

describe("Application", () => {
  let test_context: TestContext;

  beforeAll(() => {
    test_context = testSetup();
  });

  describe("form submission", () => {
    it("rerenders self", async () => {
      const component = await test_context.make_component(null, () => {
        return `
          <form action="/submit_path" method="post" data-rerender-target=":self" data-turbo="true">
            <p>Original</p>
            <input type="submit" name="Submit" />
          </form>
        `
      });

      // Create a Turbo Stream response with the updated component HTML
      const updatedComponentHTML = `
        <live-component data-livecomponent="true" data-state='{"props":{},"slots":{},"children":{}}'>
          <form action="/submit_path" method="post" data-rerender-target=":self" data-turbo="true">
            <p>Updated</p>
            <input type="submit" name="Submit" />
          </form>
        </live-component>
      `;

      const turboStreamResponse = `
        <turbo-stream action="update" target="this_id_shouldnt_exist">
          <template>${updatedComponentHTML}</template>
        </turbo-stream>
      `;

      // Mock fetch with a proper Turbo Stream Response
      const mockHeaders = new Headers({
        "Content-Type": "text/vnd.turbo-stream.html; charset=utf-8",
      });

      vi.mocked(global.fetch).mockResolvedValue({
        ok: true,
        status: 200,
        statusText: "OK",
        headers: mockHeaders,
        text: () => Promise.resolve(turboStreamResponse),
        clone: function() {
          return {
            ok: true,
            status: 200,
            statusText: "OK",
            headers: mockHeaders,
            text: () => Promise.resolve(turboStreamResponse),
          } as Response;
        },
      } as Response);

      const form = component.querySelector("form") as HTMLFormElement;
      form.requestSubmit();

      // Wait for the async fetch to be called
      await vi.waitFor(() => {
        expect(global.fetch).toHaveBeenCalled();
      });

      // Wait for the DOM to be updated
      await vi.waitFor(() => {
        const paragraph = component.querySelector("p");
        expect(paragraph?.textContent).toBe("Updated");
      });
    });

    it("does not reject when the form has no data-rerender-* attributes", async () => {
      // A plain Turbo form with no data-rerender-id / data-rerender-target
      // attributes (i.e. not managed by LiveComponent). find_rerender_target
      // returns null for these, and handle_turbo_submit_end must bail out
      // instead of trying to morph into a null element.
      const form = document.createElement("form");
      form.setAttribute("action", "/submit_path");
      form.setAttribute("method", "post");
      form.setAttribute("data-turbo", "true");
      form.innerHTML = `<input type="submit" name="Submit" />`;
      document.body.appendChild(form);

      const turboStreamResponse = `
        <turbo-stream action="update" target="this_id_shouldnt_exist">
          <template><div>ignored</div></template>
        </turbo-stream>
      `;

      const mockHeaders = new Headers({
        "Content-Type": "text/vnd.turbo-stream.html; charset=utf-8",
      });

      vi.mocked(global.fetch).mockResolvedValue({
        ok: true,
        status: 200,
        statusText: "OK",
        headers: mockHeaders,
        text: () => Promise.resolve(turboStreamResponse),
        clone: function() {
          return {
            ok: true,
            status: 200,
            statusText: "OK",
            headers: mockHeaders,
            text: () => Promise.resolve(turboStreamResponse),
          } as Response;
        },
      } as Response);

      // Catch any unhandled promise rejection produced by the
      // turbo:submit-end handler while this test runs.
      let unhandled_rejection: unknown;
      const on_unhandled_rejection = (reason: unknown) => {
        unhandled_rejection = reason;
      };
      process.on("unhandledRejection", on_unhandled_rejection);

      try {
        const submit_end = new Promise(resolve => {
          document.addEventListener("turbo:submit-end", resolve, { once: true });
        });

        form.requestSubmit();
        await submit_end;

        // A rejection from the async turbo:submit-end handler is only
        // reported as unhandledRejection once the microtask queue has
        // drained at the end of the event-loop turn, so yield one macrotask
        // before asserting.
        await new Promise(resolve => setTimeout(resolve, 0));
      } finally {
        process.off("unhandledRejection", on_unhandled_rejection);
      }

      expect(unhandled_rejection).toBeUndefined();
    });
  });
});
