import { live, LiveController } from "@camertron/live-component";

@live("AddSlotComponent")
export class AddSlotComponent extends LiveController {
  add() {
    this.render((component) => {
      component.with("item", () => "Item 3");
    });
  }
}
