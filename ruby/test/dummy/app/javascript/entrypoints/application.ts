import { Application as LiveComponentApplication } from "@camertron/live-component";
import { Application as StimulusApplication } from "@hotwired/stimulus";

import "@hotwired/turbo-rails";

import "app/components/update_props_component";
import "app/components/add_slot_component";
import "app/components/react_component";

declare global {
  interface Window {
    Stimulus: StimulusApplication;
    Live: LiveComponentApplication;
  }
}

window.Stimulus = StimulusApplication.start();
window.Live = LiveComponentApplication.start(window.Stimulus);
