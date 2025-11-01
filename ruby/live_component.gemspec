$:.unshift File.join(File.dirname(__FILE__), "lib")
require "live_component/version"

Gem::Specification.new do |s|
  s.name     = "live_component"
  s.version  = ::LiveComponent::VERSION
  s.authors  = ["Cameron Dutro"]
  s.email    = ["camertron@gmail.com"]
  s.homepage = "http://github.com/camertron/live_component"
  s.description = s.summary = "Client-side rendering and state management for ViewComponent."
  s.platform = Gem::Platform::RUBY

  s.add_dependency "railties", "~> 8.0"
  s.add_dependency "view_component", "~> 4.0"
  s.add_dependency "use_context", "~> 1.2"

  s.require_path = "lib"

  s.files = Dir["{app,config,lib,ext,spec}/**/*", "Gemfile", "LICENSE", "CHANGELOG.md", "README.md", "Rakefile", "live_component.gemspec"]
end
