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
  });
});
