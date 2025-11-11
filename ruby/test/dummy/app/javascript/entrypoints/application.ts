import { Application as LiveComponentApplication } from "@camertron/live-component";
import { Application as StimulusApplication } from "@hotwired/stimulus";

import "@hotwired/turbo-rails";

// Import all .tsx and .ts files from app/components
import.meta.glob("app/components/**/*.{ts,tsx}", { eager: true });

declare global {
  interface Window {
    Stimulus: StimulusApplication;
    Live: LiveComponentApplication;
  }
}

window.Stimulus = StimulusApplication.start();
window.Live = LiveComponentApplication.start(window.Stimulus);
