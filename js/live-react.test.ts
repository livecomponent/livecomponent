import { describe, it, expect, beforeEach } from "vitest";
// Import React from node_modules explicitly to avoid confusion with local ./react module
import * as React from "react";
import { ReactRegistry, LiveComponentReact } from "./live-react";
import { RenderRequest, State } from "./live-component";

describe("ReactRegistry", () => {
  beforeEach(() => {
    // Reset the singleton instance before each test
    (ReactRegistry as any)._instance = undefined;
  });

  describe("register_component", () => {
    it("registers a component by name", () => {
      const TestComponent = () => React.createElement("div", null, "Test");
      const registry = ReactRegistry.instance;

      registry.register_component("TestComponent", TestComponent);

      const retrieved = registry.get_component("TestComponent");
      expect(retrieved).toBe(TestComponent);
    });

    it("can be called via static method", () => {
      const TestComponent = () => React.createElement("div", null, "Test");

      ReactRegistry.register_component("TestComponent", TestComponent);

      const retrieved = ReactRegistry.instance.get_component("TestComponent");
      expect(retrieved).toBe(TestComponent);
    });
  });

  describe("get_component", () => {
    it("returns undefined for unregistered components", () => {
      const registry = ReactRegistry.instance;
      const retrieved = registry.get_component("NonExistent");
      expect(retrieved).toBeUndefined();
    });

    it("retrieves a registered component", () => {
      const TestComponent = () => React.createElement("div", null, "Test");
      const registry = ReactRegistry.instance;

      registry.register_component("MyComponent", TestComponent);

      const retrieved = registry.get_component("MyComponent");
      expect(retrieved).toBe(TestComponent);
    });
  });
});

describe("LiveComponentReact", () => {
  beforeEach(() => {
    // Reset the singleton instance before each test
    (ReactRegistry as any)._instance = undefined;

    // Register the custom element if not already registered
    if (!window.customElements.get('live-component-react')) {
      window.customElements.define('live-component-react', LiveComponentReact);
    }
  });

  describe("render", () => {
    it("renders a registered React component", async () => {
      const TestComponent = ({ message }: { message: string }) =>
        React.createElement("div", { className: "test-component" }, message);

      ReactRegistry.register_component("TestComponent", TestComponent);

      const element = document.createElement('live-component-react') as LiveComponentReact;
      document.body.appendChild(element);

      const state: State = {
        props: {
          component: "TestComponent",
          message: "Hello, React!"
        },
        slots: {},
        subs: {}
      };

      const request: RenderRequest = {
        state,
        reflexes: []
      };

      await element.render(request);

      // Wait for React to render
      await new Promise(resolve => window.requestAnimationFrame(resolve));

      const renderedDiv = element.querySelector('.test-component');
      expect(renderedDiv).toBeTruthy();
      expect(renderedDiv?.textContent).toBe("Hello, React!");

      document.body.removeChild(element);
    });

    it("reuses the same root on subsequent renders", async () => {
      const TestComponent = ({ count }: { count: number }) =>
        React.createElement("div", { className: "counter" }, `Count: ${count}`);

      ReactRegistry.register_component("Counter", TestComponent);

      const element = document.createElement('live-component-react') as LiveComponentReact;
      document.body.appendChild(element);

      const request1: RenderRequest = {
        state: {
          props: { component: "Counter", count: 1 },
          slots: {},
          subs: {}
        },
        reflexes: []
      };

      await element.render(request1);
      await new Promise(resolve => setTimeout(resolve, 0));

      const request2: RenderRequest = {
        state: {
          props: { component: "Counter", count: 2 },
          slots: {},
          subs: {}
        },
        reflexes: []
      };

      await element.render(request2);
      await new Promise(resolve => window.requestAnimationFrame(resolve));

      const renderedDiv = element.querySelector('.counter');
      expect(renderedDiv?.textContent).toBe("Count: 2");

      document.body.removeChild(element);
    });
  });

  describe("before_node_morphed", () => {
    it("copies data-id attribute from new node to old node", () => {
      const element = document.createElement('live-component-react') as LiveComponentReact;

      const oldNode = document.createElement('div');
      oldNode.setAttribute('data-id', 'old-id');

      const newNode = document.createElement('div');
      newNode.setAttribute('data-id', 'new-id');

      const result = element.before_node_morphed(oldNode, newNode);

      expect(oldNode.getAttribute('data-id')).toBe('new-id');
      expect(result).toBe(false);
    });

    it("handles nodes without data-id attribute", () => {
      const element = document.createElement('live-component-react') as LiveComponentReact;

      const oldNode = document.createElement('div');
      const newNode = document.createElement('div');

      const result = element.before_node_morphed(oldNode, newNode);

      expect(oldNode.getAttribute('data-id')).toBeNull();
      expect(result).toBe(false);
    });
  });
});
