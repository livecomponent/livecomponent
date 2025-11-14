import { describe, it, expect, beforeAll, vi } from "vitest";
import { TestContext, testSetup } from "./test-helpers/setup";

describe("LiveComponent", () => {
  let testContext: TestContext;

  beforeAll(() => {
    testContext = testSetup();
  });

  describe("render", () => {
    it("fetches a result from the server and updates the DOM", async () => {
      const component = await testContext.make_component(null, () => {
        return "<div attribute='original value'>original content</div>";
      });

      await component.render(null, () => {
        return "<div attribute='updated value'>updated content</div>";
      });

      const childDiv = component.querySelector("div");
      expect(childDiv?.getAttribute("attribute")).toBe("updated value");
      expect(childDiv?.textContent).toBe("updated content");
    });

    it("updates state", async () => {
      const state = testContext.make_state();
      state.props.foo = "bar";

      const component = await testContext.make_component(state, () => {
        return "<div attribute='value'>content</div>";
      });

      expect(component.state.props).toStrictEqual({foo: "bar"});

      state.props.foo = "baz";
      expect(component.state.props).toStrictEqual({foo: "bar"});
      await component.render(state);
      expect(component.state.props).toStrictEqual({foo: "baz"});
    });

    it("propagates state to child components", async () => {
      const state = testContext.make_state();
      state.props.parent_prop = "parent prop value";
      state.subs["abc123"] = testContext.make_state();
      state.subs["abc123"].props = { child_prop: "child prop value" };

      const component = await testContext.make_component(state, () => {
        const child = testContext.make_component_element();
        child.setAttribute("data-id", "abc123");
        return child.outerHTML;
      });

      expect(component.state.props).toStrictEqual({parent_prop: "parent prop value"});
      expect(component.state.subs["abc123"].props).toStrictEqual({child_prop: "child prop value"});
    });

    it("calls before_node_morphed before the node is replaced", async () => {
      const component_wrapper = await testContext.make_component(null, () => {
        return "<div attribute='value'>content</div>";
      });

      const morph_mock = vi.fn();
      component_wrapper.component.before_node_morphed = morph_mock;

      await component_wrapper.render(null, () => {
        return "<div attribute='updated value'>updated content</div>";
      });

      expect(morph_mock).toHaveBeenCalled();
    });

    it("morphs the node if before_node_morph returns true", async () => {
      const component_wrapper = await testContext.make_component(null, () => {
        return "<div attribute='value'>content</div>";
      });

      const morph_mock = vi.fn(() => true);
      component_wrapper.component.before_node_morphed = morph_mock;

      await component_wrapper.render(null, () => {
        return "<div attribute='updated value'>updated content</div>";
      });

      const div = component_wrapper.querySelector("div");
      expect(div.getAttribute("attribute")).toStrictEqual("updated value");
      expect(div.textContent).toStrictEqual("updated content");
    });

    it("does not morph the node if before_node_morphed returns false", async () => {
      const component_wrapper = await testContext.make_component(null, () => {
        return "<div attribute='value'>content</div>";
      });

      const morph_mock = vi.fn(() => false);
      component_wrapper.component.before_node_morphed = morph_mock;

      await component_wrapper.render(null, () => {
        return "<div attribute='updated value'>updated content</div>";
      });

      expect(morph_mock).toHaveBeenCalled();

      const div = component_wrapper.querySelector("div");
      expect(div.getAttribute("attribute")).toStrictEqual("value");
      expect(div.textContent).toStrictEqual("content");
    });
  });
});
