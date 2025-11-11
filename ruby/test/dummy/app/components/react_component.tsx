import { live, LiveController, ReactRegistry } from "@camertron/live-component";

type TestComponentProps = {
  mode: string
}

const TestComponent = ({mode}: TestComponentProps) => {
  return (
    <div>
      {mode === "start" ? "Start" : "Finish"}
    </div>
  );
}

ReactRegistry.register_component("TestComponent", TestComponent);

type ReactComponentProps = {
  mode: string
}

@live("ReactComponent")
export class ReactComponent extends LiveController<ReactComponentProps> {
  finish() {
    this.render((component) => {
      component.props.mode = "finish";
    });
  }
}
