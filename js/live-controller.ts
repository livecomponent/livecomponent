import { Controller } from "@hotwired/stimulus";
import { LiveComponent, Props, RenderRequest, State } from "./live-component";
import { ComponentBuilder } from "./component-builder";
import { Constructor } from "./constructor";
import { AsyncTaskQueue } from "./queue";
import { live } from "./live";

type RenderBlock<P> = (component: ComponentBuilder<State<P>, P>) => void;

export type LiveControllerClass<T> = {
  identifier: string
  targets: string[]
} & Constructor<T>

export type PropHook<T> = [T, (new_value: T) => void];

@live("Live")
export class LiveController<P extends Props = Props> extends Controller {
  static identifier: string;

  public state: State<P>;
  private _task_queue: AsyncTaskQueue<void> | null = null;

  get ruby_class(): string {
    return this.state.ruby_class;
  }

  get props(): P {
    return this.state.props;
  }

  private get task_queue() {
    if (!this._task_queue) {
      this._task_queue = new AsyncTaskQueue();
    }

    return this._task_queue;
  }

  find_child<T extends Props = Props>(cb: (state: State) => boolean): [string, State<T>] | null {
    for (const id in this.state.children) {
      if (cb(this.state.children[id])) {
        return [id, this.state.children[id] as State<T>];
      }
    }

    return null;
  }

  find_child_by_id<T extends State = State>(id: string, state: State = this.state): T | null {
    const child = state.children[id];
    if (child) return child as T;

    for (const child_id in state.children) {
      const child = this.find_child_by_id(id, state.children[child_id]);
      if (child) return child as T;
    }

    return null;
  }

  get id(): string {
    return this.element.getAttribute("data-id");
  }

  initialize() {
    (this.element as LiveComponent).set_controller(this);
  }

  connect() {
    this.propagate_state_from_element();
  }

  propagate_state_from_element() {
    if (this.element.hasAttribute("data-state")) {
      const state = JSON.parse(this.element.getAttribute("data-state")) as State<P>;
      this.propagate_state(state);
      this.element.removeAttribute("data-state");
    }
  }

  async propagate_state(state: State<P>) {
    for (const key in state.props) {
      const value = state.props[key];

      if (typeof value === 'string' && value.startsWith("fn:")) {
        const [id, method_name] = value.substring(3).split("#");
        const element = document.querySelector(`[data-id="${id}"]`);

        if (element instanceof LiveComponent) {
          const controller = await element._controller;

          /* @ts-ignore idk how to fix this */
          state.props[key] = (...args: any[]) => {
            return controller[method_name](...args);
          }
        } else {
          throw new Error(`Could not find live component with id '${id}'`);
        }
      }
    }

    this.before_update(state);
    this.state = state;

    for (const slot_name in this.state.slots) {
      const child_elements = this.element.querySelectorAll(`[data-slot-name="${slot_name}"]`) as NodeListOf<LiveComponent>;
      const slots = state.slots[slot_name];

      for (let i = 0; i < state.slots[slot_name].length; i ++) {
        const slot = slots[i];
        const child_element = child_elements[i];

        if (child_element) {
          const slot_controller = await child_element.controller;
          await slot_controller.propagate_state(slot);
        }
      }
    }

    for (const child_id in this.state.children) {
      const child = this.state.children[child_id];
      const child_element = this.element.querySelector(`[data-id="${child_id}"]`) as LiveComponent;

      if (child_element) {
        const child_controller = await child_element.controller;
        await child_controller.propagate_state(child);
      }
    }

    this.after_update();
  }

  async render(cb?: RenderBlock<P>): Promise<void> {
    return this.task_queue.enqueue(async () => {
      const new_state = JSON.parse(JSON.stringify(this.state)) as State<P>;
      const builder = new ComponentBuilder(new_state);
      if (cb) cb(builder);

      const request: RenderRequest = {
        state: builder.state,
        reflexes: builder.reflexes,
      }

      await (this.element as LiveComponent).render(request);
    });
  }

  // Override in derived classes. Called before new state is propagated to this
  // component.
  before_update(_new_state: State) {
  }

  // Override in derived classes. Called after new state is propagated to this
  // component.
  after_update() {
  }

  find_closest<T extends LiveController>(controller: LiveControllerClass<T>, element: Element = this.element): T | null {
    let current = element;

    while (current) {
      const child_controller = this.application.getControllerForElementAndIdentifier(current, controller.identifier) as T;
      if (child_controller) return child_controller;
      current = current.parentElement;
    }

    return null;
  }
}
