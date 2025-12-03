import { Idiomorph } from "idiomorph";
import { ComponentBuilder } from "./component-builder";
import { LiveController } from "./live-controller";
import { Application } from "./application";

export type Props<T = {[key: string]: any}> = T;
export type SlotDefs = Record<string, Props>;
export type Block = (builder: ComponentBuilder) => string | void;
export type Reflex<P extends Props = Props> = {
  method_name: string,
  props: P
}

export type State<P extends Props = Props> = {
  ruby_class?: string
  props: P
  content?: string
  slots: {
    [key: string]: State[]
  }
  children: {
    [key: string]: State
  }
}

export class LiveComponent<P extends Props = Props, SL extends SlotDefs = SlotDefs> extends HTMLElement {
  public controller: Promise<LiveController<P, SL>>;

  // non-async way of getting the controller; shold only be used by event handlers
  // and such that cannot be async
  public _controller: LiveController<P, SL> | null = null;
  private resolve_controller: (controller: LiveController<P, SL>) => void;

  constructor() {
    super();

    this._controller = null;
    this.controller = new Promise((resolve: (controller: LiveController<P, SL>) => void) => {
      this.resolve_controller = resolve;
    });
  }

  set_controller(controller: LiveController<P, SL>) {
    this.resolve_controller(controller);
    this._controller = controller;
  }

  before_node_morphed(_old_node: HTMLElement, _new_node: HTMLElement): boolean {
    return true;
  }

  get parent(): LiveComponent | null {
    const parent_el = this.parentElement;
    return parent_el?.closest("[data-livecomponent]");
  }

  async render(request: RenderRequest) {
    const controller = await this.controller;
    const result = await (await Application.instance).render(request);
    const el = document.createElement("div");
    el.innerHTML = result;
    const first_child = el.querySelector("[data-livecomponent]") as LiveComponent;
    const new_state = JSON.parse(first_child.getAttribute("data-state"));
    first_child.removeAttribute("data-state");

    Idiomorph.morph(this, first_child, {
      callbacks: {
        beforeNodeMorphed: (oldNode: HTMLElement, newNode: HTMLElement) => {
          if (oldNode instanceof LiveComponent) {
            return oldNode.before_node_morphed(oldNode, newNode);
          }

          return true;
        }
      }
    });

    controller.propagate_state(new_state);
  }
}

declare global {
  interface Window {
    LiveComponent: typeof LiveComponent
  }
}

if (!window.customElements.get('live-component')) {
  window.LiveComponent = LiveComponent;
  window.customElements.define('live-component', LiveComponent);
}

export type RenderRequest = {
  state: State,
  reflexes: Reflex[]
}
