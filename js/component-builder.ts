import { Block, Props, Reflex, State } from "./live-component";

export class ComponentBuilder<S extends State = State, P extends Props = S extends State<infer U> ? U : Props> {
  public state: S;
  public reflexes: Reflex[] = [];

  constructor(state: S) {
    this.state = state;
  }

  get props(): P {
    return this.state.props as P;
  }

  with(slot_name: string, block?: Block): ComponentBuilder<S, P>;
  with<T extends Props>(slot_name: string, props: T, block?: Block): ComponentBuilder<S, P>;
  with<T extends Props>(
    slot_name: string,
    arg1?: T | Block,
    arg2?: Block,
  ): ComponentBuilder<S, P> {
    let props: T;
    let block: Block | undefined = undefined;

    if (arg1 instanceof Function) {
      block = arg1;
      props = {} as T;
    } else {
      props = (arg1 || {}) as T;
      block = arg2 as (() => string) | undefined;
    }

    const state: State = {
      props: props,
      slots: {},
      children: {},
    };

    if (block) {
      state.content = block(new ComponentBuilder(state)) || undefined;
    }

    if (!this.state.slots[slot_name]) {
      this.state.slots[slot_name] = [];
    }

    this.state.slots[slot_name].push(state);

    return this;
  }

  call<T extends Props>(method_name: string, props?: T): ComponentBuilder<S, P> {
    this.reflexes.push({method_name, props: props || {}});
    return this;
  }
}
