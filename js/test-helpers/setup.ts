import { LiveComponent, RenderRequest, State } from "../live-component";
import { LiveController } from "../live-controller";
import { Application as LiveComponentApplication, Transport } from "../application";
import { Application as StimulusApplication } from "@hotwired/stimulus";
import { vi } from "vitest";

export class TestContext {
  public stimulusApp: StimulusApplication;
  public liveApp: LiveComponentApplication;
  public transport: Transport;

  constructor(stimulusApp: StimulusApplication, liveApp: LiveComponentApplication, transport: Transport) {
    this.stimulusApp = stimulusApp;
    this.liveApp = liveApp;
    this.transport = transport;
  }

  static make_state(): State {
    return {props: {}, slots: {}, subs: {}};
  }

  make_state(): State {
    return TestContext.make_state();
  }

  static make_request(): RenderRequest {
    return {
      state: {
        props: {},
        slots: {},
        subs: {},
      },
      reflexes: [],
    };
  }

  make_request(): RenderRequest {
    return TestContext.make_request();
  }

  make_component_element(state?: State, block?: () => string): LiveComponent {
    const component = document.createElement("live-component") as LiveComponent;
    component.setAttribute("data-livecomponent", "true");
    component.setAttribute("data-controller", "live");
    component.setAttribute("data-id", "test-component-id");
    component.setAttribute("data-state", JSON.stringify(state || this.make_state()));
    component.innerHTML = block?.() || "";
    return component;
  }

  async make_component(state?: State, block?: () => string): Promise<TestComponentWrapper> {
    const component = this.make_component_element(state, block);
    document.body.appendChild(component);

    // Wait for the controller to be initialized
    await component.controller;

    return new TestComponentWrapper(this.liveApp, component);
  }
}

export class TestComponentWrapper {
  public app: LiveComponentApplication;
  public component: LiveComponent;

  constructor(app: LiveComponentApplication, component: LiveComponent) {
    this.app = app;
    this.component = component;
  }

  async render(new_state?: State, block?: () => string) {
    const mockResponse = `
      <live-component data-livecomponent="true" data-state='${JSON.stringify(new_state || TestContext.make_state())}'>
        ${block?.() ?? ""}
      </live-component>
    `;

    const mockTransport = this.app.transport;
    vi.mocked(mockTransport.render).mockResolvedValue(mockResponse);

    const request = TestContext.make_request();
    await this.component.render(request);
  }

  set innerHTML(new_value: string) {
    this.component.innerHTML = new_value;
  }

  get innerHTML(): string {
    return this.component.innerHTML;
  }

  get outerHTML(): string {
    return this.component.outerHTML;
  }

  get state(): State {
    return this.component._controller.state;
  }

  querySelector(...props: Parameters<HTMLElement["querySelector"]>): ReturnType<HTMLElement["querySelector"]> {
    return this.component.querySelector(...props);
  }

  get controller(): Promise<LiveController> {
    return this.component.controller
  }
}

export const testSetup = (): TestContext => {
  // Manually register the LiveComponent custom element
  // (the module-level registration doesn't work in test environment)
  if (!window.customElements.get("live-component")) {
    window.customElements.define("live-component", LiveComponent);
  }

  // Initialize Stimulus application once
  const stimulusApp = StimulusApplication.start();

  // Register the default LiveController with Stimulus
  stimulusApp.register("live", LiveController);

  // Create a mock transport that returns HTML
 const mockTransport = {
    start: vi.fn(),
    render: vi.fn(),
  };

  // Initialize LiveComponent application with Stimulus (only once)
  const liveApp = LiveComponentApplication.start(stimulusApp, mockTransport);

  return new TestContext(stimulusApp, liveApp, mockTransport);
};
