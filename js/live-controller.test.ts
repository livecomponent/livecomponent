import { describe, it, expect, beforeAll, vi } from "vitest";
import { TestContext, testSetup } from "./test-helpers/setup";
import { LiveComponent, State } from "./live-component";
import { live } from "./live";
import { LiveController } from "./live-controller";

@live("ParentComponent")
class ParentComponent extends LiveController {
}

@live("ChildComponent")
class ChildComponent extends LiveController {
}

describe("LiveController", () => {
  let testContext: TestContext;

  beforeAll(() => {
    testContext = testSetup();
  });

  describe("find_sub", () => {
    it("yields all children to the block", async () => {
      const state = testContext.make_state();
      state.children["abc123"] = testContext.make_state();

      const component = await testContext.make_component(state, () => {
        const child = testContext.make_component_element();
        child.setAttribute("data-id", "abc123");
        return child.outerHTML;
      });

      const controller = await component.controller;
      const yielded_children = [];

      controller.find_child((sub: State) => {
        yielded_children.push(sub);
        return false;
      });

      expect(yielded_children).toStrictEqual([
        state.children["abc123"]
      ]);
    });

    it("returns the matching sub", async () => {
      const state = testContext.make_state();
      state.children["abc123"] = testContext.make_state();

      const component = await testContext.make_component(state, () => {
        const child = testContext.make_component_element();
        child.setAttribute("data-id", "abc123");
        return child.outerHTML;
      });

      const controller = await component.controller;
      const sub = controller.find_child(() => true);

      expect(sub).toStrictEqual(["abc123", state.children["abc123"]]);
    });
  });

  describe("find_sub_by_id", () => {
    it("finds the sub by it's id", async () => {
      const state = testContext.make_state();
      state.children["abc123"] = testContext.make_state();

      const component = await testContext.make_component(state, () => {
        const child = testContext.make_component_element();
        child.setAttribute("data-id", "abc123");
        return child.outerHTML;
      });

      const controller = await component.controller;

      const sub = controller.find_child_by_id("abc123");
      expect(sub).toStrictEqual(state.children["abc123"]);
    });
  });

  describe("id", () => {
    it("gets the component's id", async () => {
      const component = await testContext.make_component(null, () => {
        return "<div attribute='original value'>original content</div>";
      });

      const controller = await component.controller;
      expect(controller.id).toStrictEqual("test-component-id");
    })
  });

  // this method gets called implicitly when the element connects to the DOM
  describe("propagate_state_from_element", () => {
    it("propagates state from the element's data-state attribute", async () => {
      const state = testContext.make_state();
      state.props.foo = "bar";

      const component = await testContext.make_component(state, () => {
        return "<div attribute='original value'>original content</div>";
      });

      expect(component.state.props).toStrictEqual({foo: "bar"});
    });
  });

  describe("before_update", () => {
    it("gets called before the update occurs", async () => {
      const state = testContext.make_state();
      state.props.foo = "bar";

      const component = await testContext.make_component(state, () => {
        return "<div attribute='original value'>original content</div>";
      });

      const controller = await component.controller;
      let state_before_update: State;

      const before_update_mock = vi.fn(() => {
        state_before_update = JSON.parse(JSON.stringify(component.state))
      });

      controller.before_update = before_update_mock;
      state.props.foo = "baz";
      await component.render(state);

      expect(before_update_mock).toHaveBeenCalled();
      expect(state_before_update.props).toStrictEqual({foo: "bar"});
    });
  });

  describe("after_update", () => {
    it("gets called after the update occurs", async () => {
      const state = testContext.make_state();
      state.props.foo = "bar";

      const component = await testContext.make_component(state, () => {
        return "<div attribute='original value'>original content</div>";
      });

      const controller = await component.controller;
      let state_before_update: State;

      const after_update_mock = vi.fn(() => {
        state_before_update = JSON.parse(JSON.stringify(component.state))
      });

      controller.after_update = after_update_mock;
      state.props.foo = "baz";
      await component.render(state);

      expect(after_update_mock).toHaveBeenCalled();
      expect(state_before_update.props).toStrictEqual({foo: "baz"});
    });
  });

  describe("find_closest", () => {
    it("traverses up the DOM searching for the given controller class", async () => {
      const page = document.createElement("div");
      page.innerHTML = `
        <lc-parentcomponent data-livecomponent="true" data-controller="parentcomponent" data-id="abc123">
          <div>
            <lc-childcomponent data-livecomponent="true" data-controller="childcomponent" data-id="def456">
            </lc-childcomponent>
          </div>
        </lc-parentcomponent>
      `;

      document.body.appendChild(page);

      const child_element = page.querySelector("[data-controller='childcomponent']") as LiveComponent;
      const controller = await child_element.controller as ChildComponent;
      expect(controller.id).toStrictEqual("def456");

      const parent = controller.find_closest(ParentComponent);
      expect(parent.id).toStrictEqual("abc123");
    });
  });
});
