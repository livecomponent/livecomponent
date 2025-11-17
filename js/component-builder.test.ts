import { ComponentBuilder } from "./component-builder";
import { TestContext } from "./test-helpers/setup";
import { describe, it, expect } from "vitest";

describe("ComponentBuilder", () => {
  describe("with", () => {
    it("adds the slot with the given slot name", () => {
      const builder = new ComponentBuilder(TestContext.make_state());
      expect(builder.state.slots["item"]?.length ?? 0).toBe(0);
      builder.with("item");
      expect(builder.state.slots["item"].length).toBe(1);
    });

    it("defaults to an empty props object", () => {
      const builder = new ComponentBuilder(TestContext.make_state());
      builder.with("item");
      expect(builder.state.slots["item"][0].props).toStrictEqual({});
    });

    it("defaults to an empty slots object", () => {
      const builder = new ComponentBuilder(TestContext.make_state());
      builder.with("item");
      expect(builder.state.slots["item"][0].slots).toStrictEqual({});
    });

    it("defaults to an empty children object", () => {
      const builder = new ComponentBuilder(TestContext.make_state());
      builder.with("item");
      expect(builder.state.slots["item"][0].children).toStrictEqual({});
    });

    it("allows a block as the second argument", () => {
      const builder = new ComponentBuilder(TestContext.make_state());
      builder.with("item", () => "content");
      expect(builder.state.slots["item"][0].content).toStrictEqual("content");
    });

    it("allows props as the second argument", () => {
      const builder = new ComponentBuilder(TestContext.make_state());
      builder.with("item", {"foo": "bar"});
      expect(builder.state.slots["item"][0].props).toStrictEqual({"foo": "bar"});
    });

    it("allows props as the second argument and a block as the third", () => {
      const builder = new ComponentBuilder(TestContext.make_state());
      builder.with("item", {"foo": "bar"}, () => "content");
      expect(builder.state.slots["item"][0].props).toStrictEqual({"foo": "bar"});
      expect(builder.state.slots["item"][0].content).toStrictEqual("content");
    });
  });

  describe("call", () => {
    it("adds a reflex", () => {
      const builder = new ComponentBuilder(TestContext.make_state());
      expect(builder.reflexes.length).toBe(0);
      builder.call("method", {"foo": "bar"});
      expect(builder.reflexes.length).toBe(1);
      expect(builder.reflexes[0]).toStrictEqual(
        {method_name: "method", props: {"foo": "bar"}}
      );
    });

    it("defaults to an empty props object", () => {
      const builder = new ComponentBuilder(TestContext.make_state());
      builder.call("method");
      expect(builder.reflexes[0].props).toStrictEqual({});
    });
  });
});
