// Package-consumer smoke test: compiled by `npm run check:dist-types` against
// the freshly built declarations in dist/. Resolving through the package's
// exports catches issues that direct relative imports would miss.
import {
  Application,
  HTTPTransport,
  LiveComponent,
  LiveController,
  WebSocketsTransport,
  live,
} from "@camertron/live-component";
import type {
  RenderRequest,
  RenderResponse,
  Transport,
} from "@camertron/live-component";

const transport: Transport = new HTTPTransport();
const _classes = [Application, LiveComponent, LiveController, WebSocketsTransport];
const _fns = [live];
const _render: (r: RenderRequest) => Promise<RenderResponse> = (r) => transport.render(r);

import {
  LiveComponentReact,
  LiveControllerReact,
  ReactRegistry,
} from "@camertron/live-component/react";
const _react = [LiveComponentReact, LiveControllerReact, ReactRegistry];
