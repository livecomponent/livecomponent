# frozen_string_literal: true

module LiveComponent
  class InstallGenerator < Rails::Generators::Base
    ENTRYPOINT_PATHS = %w(
      app/javascript/entrypoints/application.ts
      app/javascript/entrypoints/application.tsx
      app/javascript/entrypoints/application.js
      app/javascript/entrypoints/application.jsx
    )

    ENTRYPOINT_PATHS.freeze

    IMPORT_STATEMENTS = <<~TYPESCRIPT.split(/\r?\n/).freeze
      // Import with aliases to distinguish the two Application classes
      import { Application as LiveComponentApplication } from "@camertron/live-component";
      import { Application as StimulusApplication } from "@hotwired/stimulus";
    TYPESCRIPT

    TS_DECLARATIONS = <<~TYPESCRIPT.split(/\r?\n/).freeze
      // Add some declarations on window to make the TypeScript compiler happy
      declare global {
        interface Window {
          Stimulus: StimulusApplication;
          Live: LiveComponentApplication;
        }
      }
    TYPESCRIPT

    STATEMENTS = <<~TYPESCRIPT.split(/\r?\n/).freeze
      // Start both the Stimulus and LiveComponent applications
      window.Stimulus = StimulusApplication.start();
      window.Live = LiveComponentApplication.start(window.Stimulus);
    TYPESCRIPT

    source_root File.expand_path("templates", __dir__)

    def copy_initializer_file
      copy_file "initializer.rb", "config/initializers/live_component.rb"
    end

    def install_lc_js_package
      install_js_package("@camertron/live-component")
    end

    def add_js_entrypoint_code
      if !relative_entrypoint
        say "Could not find a JavaScript entrypoint file", :red
        return
      end

      lines = File
        .read(absolute_entrypoint)
        .split(/\r?\n/)

      if lines.include?(STATEMENTS.last)
        say_status :identical, relative_entrypoint, :blue
        return
      end

      import_lines = lines
        .each_with_index
        .select do |line, _|
          line =~ /import.*(?:from.*)?(?:;|$)/
        end

      _, lineno = import_lines.last
      lineno = lineno ? lineno + 1 : 0

      if lineno > 0
        lines.insert(lineno, "")
        lineno += 1
      end

      lines.insert(lineno, *IMPORT_STATEMENTS)
      lines << ""

      if ts?(absolute_entrypoint)
        lines.concat(TS_DECLARATIONS)
        lines << ""
      end

      lines.concat(STATEMENTS)

      File.write(absolute_entrypoint, lines.join("\n"))

      say_status :modify, relative_entrypoint
    end

    private

    def js_package_manager
      @js_package_manager ||= begin
        rails_root = destination_root

        if File.exist?(File.join(rails_root, "pnpm-lock.yaml"))
          :pnpm
        elsif File.exist?(File.join(rails_root, "yarn.lock"))
          :yarn
        elsif File.exist?(File.join(rails_root, "package-lock.json"))
          :npm
        elsif File.exist?(File.join(rails_root, "bun.lockb"))
          :bun
        else
          :unknown
        end
      end
    end

    def js_entrypoint
      @js_entrypoint ||= begin
        rails_root = destination_root

        ENTRYPOINT_PATHS
          .map { |path| [path, File.join(rails_root, path)] }
          .find { |relative, absolute| File.exist?(absolute) }
      end
    end

    def relative_entrypoint
      js_entrypoint.first
    end

    def absolute_entrypoint
      js_entrypoint.last
    end

    def install_js_package(package_name)
      command = case js_package_manager
      when :npm
        "npm install #{package_name}"
      when :yarn
        "yarn add #{package_name}"
      when :pnpm
        "pnpm add #{package_name}"
      when :bun
        "bun add #{package_name}"
      else
        say "Unknown package manager. Please install #{package_name} manually.", :red
        return
      end

      run command
    end

    def ts?(path)
      extname = File.extname(path)
      extname == ".ts" || extname == ".tsx"
    end
  end
end
