import { TurboSubmitEndEvent, TurboSubmitStartEvent } from "@hotwired/turbo";
import { Application as Stimulus } from "@hotwired/stimulus"
import { Idiomorph } from "idiomorph";
import { LiveComponent, RenderRequest } from "./live-component";
import { HTTPTransport } from "./http-transport";

export interface Transport {
  start(): void;
  render(request: RenderRequest): Promise<string>;
}

export class Application {
  private static application: Application;
  private static application_promise: Promise<Application>;
  private static resolve_application: (application: Application) => void;

  static get instance(): Promise<Application> {
    if (!this.application_promise) {
      this.application_promise = new Promise(resolve => {
        this.resolve_application = resolve;
      });
    }

    return this.application_promise;
  }

  static handle_turbo_submit_start(event: TurboSubmitStartEvent) {
    const element = Application.find_rerender_target(event.target as HTMLFormElement);
    if (!element) return;
    if (!element._controller) return;

    const rerender_id = element.getAttribute("data-id");
    if (!rerender_id) return;

    // controller is set async, but this event handler can't be async, so we use the sync _controller
    // property instead; things should be wired up by the time this event fires
    const controller = element._controller;

    event.detail.formSubmission.body.set("__lc_rerender_state", JSON.stringify(controller.state));
    event.detail.formSubmission.body.set("__lc_rerender_id", rerender_id);
  }

  private static find_rerender_target(form: HTMLFormElement): LiveComponent | null {
    if (form.hasAttribute("data-rerender-id")) {
      const rerender_id = form.getAttribute("data-rerender-id");
      const element = document.querySelector(`[data-id="${rerender_id}"]`) as LiveComponent | undefined;
      return element || null;
    }

    if (form.hasAttribute("data-rerender-target")) {
      const target_ident = form.getAttribute("data-rerender-target");

      switch (target_ident) {
        case ":self":
          return form.closest("[data-livecomponent]");
        case ":parent":
          const self = form.closest("[data-livecomponent]") as LiveComponent;
          return self?.parent;
        default:
          return form.closest(`[data-livecomponent][data-controller='${target_ident}']`)
      }
    }

    return null;
  }

  static async handle_turbo_submit_end(event: TurboSubmitEndEvent) {
    const element = Application.find_rerender_target(event.target as HTMLFormElement);
    const response = await event.detail.fetchResponse.responseHTML;

    // strip away the turbo-frame and template tags
    const dummy_element = document.createElement("div");
    dummy_element.innerHTML = response;
    const html = dummy_element.querySelector("template").innerHTML;
    const el = document.createElement("div");
    el.innerHTML = html;

    Idiomorph.morph(element, el.firstChild);

    const controller = await element.controller;
    controller.propagate_state_from_element();
  }

  static start(stimulus: Stimulus, transport?: Transport) {
    if (this.application) {
      return this.application;
    }

    if (!this.resolve_application) {
      Application.instance;
    }

    transport ||= new HTTPTransport();
    transport.start();

    document.addEventListener("turbo:submit-start", this.handle_turbo_submit_start);
    document.addEventListener("turbo:submit-end", this.handle_turbo_submit_end);

    this.application = new Application(stimulus, transport);
    this.resolve_application(this.application);

    return this.application;
  }

  public transport: Transport;
  public stimulus: Stimulus;

  protected constructor(stimulus: Stimulus, transport: Transport) {
    this.transport = transport;
    this.stimulus = stimulus;
  }

  async render(request: RenderRequest): Promise<string> {
    return this.transport.render(request);
  }
}

declare global {
  interface Window {
    LiveComponentApplication: Application;
  }
}
