# Unreleased
* Added `LiveComponent::Renderer` as the single render entry point behind both transports.
* Middleware and `LiveComponentChannel` are now thin transport adapters; errors rescue `StandardError` instead of `Exception`.
* ActionCable responses are transmitted only to the requesting connection instead of broadcast to all subscribers.
* Removed the unused `post /render` route, `RenderController#show`, and `show.html.erb`.
* Error messages now report the raising exception's class (e.g. `RuntimeError`) instead of the `ActionView::Template::Error` wrapper.
* Cable error responses always include a `backtrace` array (previously could be `null`).

# 0.4.0
* See js/CHANGELOG.md.

# 0.3.0
* Only use `CompressionStream` if it's available, i.e. we're running in a modern-ish browser.

# 0.2.0
* Rename `ModelSerializer`'s `load` option to `reload`, since that's what it does.
* Rename `ModelSerializer#add_serializer` to `#register` for consistency with other parts of the library.

# 0.1.1
* Compress requests and responses.

# 0.1.0
* Birthday!
