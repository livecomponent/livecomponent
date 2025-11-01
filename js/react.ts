import * as React from "react";
import { createRoot, Root } from "react-dom/client";
import { live } from "./live";
import { LiveComponent, RenderRequest, State } from "./live-component";
import { LiveController } from "./live-controller";

// Define ComponentType locally to avoid circular import with react
type ComponentType<P = {}> = React.ComponentType<P>;

export class ReactRegistry {
  private static _instance: ReactRegistry;

  static get instance(): ReactRegistry {
    if (!this._instance) {
      this._instance = new ReactRegistry()
    }

    return this._instance;
  }

  private registered_components: {[key: string]: ComponentType<any>} = {};

  static register_component(...args: Parameters<ReactRegistry["register_component"]>): ReturnType<ReactRegistry["register_component"]> {
    return this.instance.register_component(...args);
  }

  register_component(name: string, component: ComponentType<any>) {
    this.registered_components[name] = component;
  }

  get_component(name: string): ComponentType<any> | undefined {
    return this.registered_components[name];
  }
}

export class LiveComponentReact extends LiveComponent {
  private root: Root | null = null;

  async render(request: RenderRequest) {
    const component_name = request.state.props.component;
    const component = ReactRegistry.instance.get_component(component_name);

    if (!this.root) {
      this.root = createRoot(this);
    }

    // @ts-ignore - using global React to avoid circular import
    this.root.render(React.createElement(component, request.state.props));
  }

  before_node_morphed(old_node: HTMLElement, new_node: HTMLElement): boolean {
    const id = new_node.getAttribute("data-id");
    if (id) old_node.setAttribute("data-id", id);
    return false;
  }
}

declare global {
  interface Window {
    LiveComponentReact: typeof LiveComponentReact
  }
}

if (!window.customElements.get('live-component-react')) {
  window.LiveComponentReact = LiveComponentReact;
  window.customElements.define('live-component-react', LiveComponentReact);
}

@live("LiveReact")
export class LiveControllerReact extends LiveController {
  async render() {
    await (this.element as LiveComponent).render({ state: this.state, reflexes: [] });
  }

  async propagate_state(state: State) {
    // wire up functions declared via the fn() method in Ruby
    for (const key in state.props) {
      const value = state.props[key];

      if (typeof value === 'string' && value.startsWith("fn:")) {
        const [id, method_name] = value.substring(3).split("#");
        const element = document.querySelector(`[data-id="${id}"]`);

        if (element instanceof LiveComponent) {
          const controller = element._controller;

          if (controller) {
            state.props[key] = (...args: any[]) => {
              return controller[method_name](...args);
            }
          } else {
            throw new Error(`Controller not yet initialized for live component with id '${id}'`);
          }
        } else {
          throw new Error(`Could not find live component with id '${id}'`);
        }
      }
    }

    this.before_update(state);

    this.state = state;
    await this.render();

    this.after_update();
  }
}
