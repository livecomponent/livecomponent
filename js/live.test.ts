import { describe, it, expect, beforeAll, vi } from "vitest";
import { TestContext, testSetup } from "./test-helpers/setup";
import { LiveComponent } from "./live-component";
import { live } from "./live";
import { LiveController } from "./live-controller";

@live("LiveTestComponent")
class LiveTestComponent extends LiveController {
  static targets = ["foo", "bar"];
}

interface LiveTestComponent {
  get fooTargetComponent(): NsLiveTestComponent;
  get barTargetComponent(): NsLiveTestComponent;
}

@live("Namespace::LiveTestComponent")
class NsLiveTestComponent extends LiveController {
}

describe("@live", () => {
  let testContext: TestContext;

  beforeAll(() => {
    testContext = testSetup();
  });

  it("prefixes the custom element name if the Ruby class name is only one word", () => {
    expect(window.customElements.get("lc-livetestcomponent")).toBeDefined();
  });

  it("uses a custom element name based on the fully-qualified Ruby class name, including namespaces, and does not prefix when more than one word", () => {
    expect(window.customElements.get("namespace-livetestcomponent")).toBeDefined();
  });

  it("defines component target methods", () => {
    const property_names = Object.getOwnPropertyNames(LiveTestComponent.prototype);
    expect(property_names).toContain("fooTargetComponent");
    expect(property_names).toContain("barTargetComponent");
  });

  it("ensures calling target methods retrieves the correct component", async () => {
    const page = document.createElement("div");
    page.innerHTML = `
      <lc-livetestcomponent data-livecomponent="true" data-controller="livetestcomponent" data-id="abc123">
        <namespace-livetestcomponent
          data-livecomponent="true"
          data-controller="namespace-livetestcomponent"
          data-id="def456"
        >
          <div data-livetestcomponent-target="foo">
            Foo
          </div>
        </namespace-livetestcomponent>
        <namespace-livetestcomponent
          data-livecomponent="true"
          data-controller="namespace-livetestcomponent"
          data-id="ghi789"
        >
          <div data-livetestcomponent-target="bar">
            Bar
          </div>
        </namespace-livetestcomponent>
      </lc-livetestcomponent>
    `;

    document.body.appendChild(page);

    const component = document.querySelector("lc-livetestcomponent") as LiveComponent;
    const controller = await component.controller as LiveTestComponent;

    expect(controller.fooTargetComponent.id).toStrictEqual("def456");
    expect(controller.barTargetComponent.id).toStrictEqual("ghi789");
  });
});
