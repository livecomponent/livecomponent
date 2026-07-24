import { Context, Controller } from "@hotwired/stimulus";
import { ErrorResponse, LiveComponent, Props, RenderRequest, SlotDefs, State } from "./live-component";
import { ComponentBuilder } from "./component-builder";
import { Constructor } from "./constructor";
import { AsyncTaskQueue, Task, TaskOptions } from "./queue";
import { live } from "./live";
import { show_error_dialog } from "./error-dialog";

/* @ts-ignore Whattt the hell */
type RenderBlock<P, SL extends SlotDefs> = (component: ComponentBuilder<State<P>, P, SL>) => void;

export type LiveControllerClass<T extends Controller> = {
  identifier: string
  targets: string[]
} & Constructor<T>

@live("Live")
export class LiveController<P extends Props = Props, SL extends SlotDefs = SlotDefs> extends Controller {
  static identifier: string;

  /* @ts-ignore */
  public state: State<P>;
  private _task_queue: AsyncTaskQueue<void> | null = null;

  constructor(context: Context) {
    super(context);

    // avoid having to remember to call super in derived classes
    const this_init = this.initialize;
    this.initialize = function() {
      (this.element as LiveComponent<P, SL>).set_controller(this);
      if (this_init) this_init();
    }

    const this_connect = this.connect;
    this.connect = function() {
      this.propagate_state_from_element();
      if (this_connect) this_connect();
    }
  }

  get ruby_class(): string | undefined {
    return this.state.ruby_class;
  }

  get props(): P {
    return this.state.props;
  }

  protected get task_queue() {
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
    return this.element.getAttribute("data-id")!;
  }

  propagate_state_from_element() {
    if (this.element.hasAttribute("data-state")) {
      const state = JSON.parse(this.element.getAttribute("data-state")!) as State<P>;
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
            /* @ts-ignore */
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

  render(options?: TaskOptions): Task<void>
  render(options?: TaskOptions, cb?: RenderBlock<P, SL>): Task<void>
  render(cb?: RenderBlock<P, SL>): Task<void>
  render(arg1?: TaskOptions | RenderBlock<P, SL>, arg2?: RenderBlock<P, SL>): Task<void> {
    let cb: RenderBlock<P, SL> | undefined = undefined;
    let options: TaskOptions | undefined = undefined;

    if (typeof arg1 === "function") {
      cb = arg1;
    } else {
      options = arg1;
      cb = arg2;
    }

    const task_fn = (async (task?: Task<any>) => {
      const new_state = JSON.parse(JSON.stringify(this.state)) as State<P>;
      const builder = new ComponentBuilder<State<P>, P, SL>(new_state);
      if (cb) cb(builder);

      const request: RenderRequest = {
        state: builder.state,
        reflexes: builder.reflexes,
      }

      if (task?.canceled) return;

      await (this.element as LiveComponent).render(request, task);
    });

    const task = this.task_queue.enqueue(task_fn, options);

    // The queue's underlying promise rejects on failure, but callers frequently
    // don't attach their own .catch/await, which produces unhandled promise
    // rejections. Attach an internal catch that surfaces the failure via the
    // error dialog; Task#catch delegates to the underlying promise, so this
    // marks the rejection handled while still leaving callers free to attach
    // their own handlers to the returned task.
    task.catch((err) => {
      const error_response: ErrorResponse = {
        success: false,
        status: "client-error",
        message: err?.message ?? String(err),
        body: err?.stack ?? String(err),
        backtrace: err?.stack?.split("\n"),
      };

      show_error_dialog(error_response);
    });

    return task;
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
    let current: Element | null = element;

    while (current) {
      const child_controller = this.application.getControllerForElementAndIdentifier(current, controller.identifier) as T;
      if (child_controller) return child_controller;
      current = current.parentElement;
    }

    return null;
  }
}
