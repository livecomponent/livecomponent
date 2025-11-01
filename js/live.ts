import { Controller } from "@hotwired/stimulus";
import { Application } from "./application";
import { LiveComponent } from "./live-component";
import { LiveControllerClass, LiveController } from "./live-controller";

export function live(ruby_class_name: string) {
  const controller_name = ruby_class_name.replace("::", "-").toLowerCase();
  const custom_element_name =
    controller_name.split("-").length === 1 ?
      `lc-${controller_name}` :
      controller_name;

  if (!window.customElements.get(custom_element_name)) {
    window.customElements.define(custom_element_name, class extends LiveComponent { });
  }

  return function<T extends LiveControllerClass<Controller>>(constructor: T) {
    Application.instance.then(app => {
      app.stimulus.register(controller_name, constructor);
      constructor.identifier = controller_name;
    });

    for (const target_name of constructor.targets) {
      Object.defineProperties(constructor.prototype, properties_for_target(target_name));
    }

    return constructor;
  };
}

function properties_for_target(target_name: string) {
  return {
    [`${target_name}TargetComponent`]: {
      get(this: LiveController | null): LiveController | null {
        if (!this) return null;

        const element = this.targets.find(target_name);
        if (!element) return null;

        return (element.closest("[data-livecomponent]:not([data-controller=livereact])") as LiveComponent)?._controller || null;
      }
    }
  };
}
