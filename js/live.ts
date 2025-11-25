import { Controller as StimulusController } from "@hotwired/stimulus";
import { Application } from "./application";
import { LiveControllerClass } from "./live-controller";

export function live(ruby_class_name: string) {
  return function<T extends LiveControllerClass<StimulusController>>(constructor: T) {
    Application.register(ruby_class_name, constructor);
  };
}
