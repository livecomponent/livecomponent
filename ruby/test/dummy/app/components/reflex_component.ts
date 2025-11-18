import { live, LiveController } from "@camertron/live-component";

@live("ReflexComponent")
class ReflexComponent extends LiveController {
  change() {
    this.render((component) => {
      component.call("change");
    });
  }
}
