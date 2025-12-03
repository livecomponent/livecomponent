import { Block, Props, Reflex, SlotDefs, State } from "./live-component";

export class ComponentBuilder<
  S extends State = State,
  P extends Props = S extends State<infer U> ? U : Props,
  SL extends SlotDefs = SlotDefs
> {
  public state: S;
  public reflexes: Reflex[] = [];

  constructor(state: S) {
    this.state = state;
  }

  get props(): P {
    return this.state.props as P;
  }

  // overload with props
  with<K extends string>(
    slot_name: K,
    props: K extends keyof SL ? SL[K] : Props,
    block?: Block
  ): ComponentBuilder<S, P, SL>;

  // overload with just a block
  with(slot_name: string, block?: Block): ComponentBuilder<S, P, SL>;

  with<T extends Props>(
    slot_name: string,
    arg1?: T | Block,
    arg2?: Block,
  ): ComponentBuilder<S, P, SL> {
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

  call<T extends Props>(method_name: string, props?: T): ComponentBuilder<S, P, SL> {
    this.reflexes.push({method_name, props: props || {}});
    return this;
  }
}
