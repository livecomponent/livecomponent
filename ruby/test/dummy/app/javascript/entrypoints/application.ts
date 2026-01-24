import { Application as LiveComponentApplication, WebSocketsTransport } from "@camertron/live-component";
import { Application as StimulusApplication } from "@hotwired/stimulus";
// import { consumer } from "../channels/consumer";
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
// const transport = new WebSocketsTransport(consumer);
window.Live = LiveComponentApplication.start(window.Stimulus);
