# 0.5.0
* The built-in error dialog is now disabled by default in production builds (`process.env.NODE_ENV === "production"`); render failures are logged with `console.error` instead. Override with `Application.start(stimulus, transport, { error_dialog: true | false })`.
* Render failures now dispatch a cancelable, bubbling `livecomponent:error` `CustomEvent` (`detail` is the `ErrorResponse`) on the component element. The built-in error dialog is the default action and is skipped when a listener calls `preventDefault()`, so apps can surface errors their own way, per component or via a `document`-level listener.
* Fix `HTTPTransport#render` not awaiting `render_request`, so transport failures resolve to a client-error response instead of rejecting.
* Queued render failures no longer surface as unhandled promise rejections.
* The error dialog now escapes the error message, body and backtrace before inserting them into the DOM.

# 0.4.0
* Allow renders (tasks) to be canceled.
* Allow renders (tasks) to be preempted. Preempted tasks cause existing tasks to be dequeued and canceled.

# 0.3.0
* Only use `CompressionStream` if it's available, i.e. we're running in a modern-ish browser.

# 0.2.0
* Added additional convenience methods and tests to make working with serialized Ruby objects easier.

# 0.1.4
* Allow component registration without using the ts-only `@live` decorator.
  - You can now call `Application.register(ruby_class_name, JavaScriptClass)`, which does the same thing.

# 0.1.3
* Compress requests and responses

# 0.1.0
* Birthday!
