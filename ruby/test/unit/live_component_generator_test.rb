# frozen_string_literal: true

require_relative "../test_helper"
require "generators/live_component/install_generator"
require "rails/generators/test_case"

class LiveComponent::InstallGeneratorTest < Rails::Generators::TestCase
  tests LiveComponent::InstallGenerator
  destination File.expand_path("../../tmp/generator_test", __dir__)
  setup :prepare_destination

  def setup
    super

    LiveComponent::InstallGenerator.class_eval do
      def install_lc_js_package
        # do nothing since we're just testing the logic and not actual package installation
      end
    end
  end

  test "copies the initializer file" do
    create_entrypoint("app/javascript/entrypoints/application.js", "")
    run_generator

    assert_file "config/initializers/live_component.rb" do |content|
      assert_match(/require "live_component"/, content)
      assert_match(/LiveComponent::Middleware/, content)
    end
  end

  test "detects npm as package manager" do
    create_package_lock_file("package-lock.json")
    assert_equal :npm, generator.send(:js_package_manager)
  end

  test "detects yarn as package manager" do
    create_package_lock_file("yarn.lock")
    assert_equal :yarn, generator.send(:js_package_manager)
  end

  test "detects pnpm as package manager" do
    create_package_lock_file("pnpm-lock.yaml")
    assert_equal :pnpm, generator.send(:js_package_manager)
  end

  test "detects bun as package manager" do
    create_package_lock_file("bun.lockb")
    assert_equal :bun, generator.send(:js_package_manager)
  end

  test "handles unknown package manager" do
    assert_equal :unknown, generator.send(:js_package_manager)
  end

  test "adds code to TypeScript entrypoint" do
    create_entrypoint("app/javascript/entrypoints/application.ts", <<~TYPESCRIPT)
      import { Application } from "@hotwired/stimulus";

      const application = Application.start();
    TYPESCRIPT

    run_generator

    assert_file "app/javascript/entrypoints/application.ts" do |content|
      assert_match(/import { Application as LiveComponentApplication } from "@camertron\/live-component"/, content)
      assert_match(/import { Application as StimulusApplication } from "@hotwired\/stimulus"/, content)
      assert_match(/declare global/, content)
      assert_match(/interface Window/, content)
      assert_match(/window\.Stimulus = StimulusApplication\.start\(\)/, content)
      assert_match(/window\.Live = LiveComponentApplication\.start\(window\.Stimulus\)/, content)
    end
  end

  test "adds code to JavaScript entrypoint" do
    create_entrypoint("app/javascript/entrypoints/application.js", <<~JAVASCRIPT)
      import { Application } from "@hotwired/stimulus";

      const application = Application.start();
    JAVASCRIPT

    run_generator

    assert_file "app/javascript/entrypoints/application.js" do |content|
      assert_match(/import { Application as LiveComponentApplication } from "@camertron\/live-component"/, content)
      assert_match(/import { Application as StimulusApplication } from "@hotwired\/stimulus"/, content)
      assert_no_match(/declare global/, content)
      assert_match(/window\.Stimulus = StimulusApplication\.start\(\)/, content)
      assert_match(/window\.Live = LiveComponentApplication\.start\(window\.Stimulus\)/, content)
    end
  end

  test "adds declarations to tsx entrypoint" do
    create_entrypoint("app/javascript/entrypoints/application.tsx", <<~TSX)
      import { Application } from "@hotwired/stimulus";

      const application = Application.start();
    TSX

    run_generator

    assert_file "app/javascript/entrypoints/application.tsx" do |content|
      assert_match(/declare global/, content)
    end
  end

  test "adds code to jsx entrypoint" do
    create_entrypoint("app/javascript/entrypoints/application.jsx", <<~JSX)
      import { Application } from "@hotwired/stimulus";

      const application = Application.start();
    JSX

    run_generator

    assert_file "app/javascript/entrypoints/application.jsx" do |content|
      assert_no_match(/declare global/, content)
    end
  end

  test "inserts imports after existing imports" do
    create_entrypoint("app/javascript/entrypoints/application.ts", <<~TYPESCRIPT)
      import { Application } from "@hotwired/stimulus";
      import { Turbo } from "@hotwired/turbo-rails";

      const application = Application.start();
    TYPESCRIPT

    run_generator

    assert_file "app/javascript/entrypoints/application.ts" do |content|
      lines = content.split("\n")
      turbo_index = lines.index { |l| l.include?("@hotwired/turbo-rails") }
      lc_index = lines.index { |l| l.include?("@camertron/live-component") }

      assert turbo_index < lc_index, "LiveComponent imports should come after existing imports"
    end
  end

  test "handles entrypoint with no existing imports" do
    create_entrypoint("app/javascript/entrypoints/application.ts", <<~TYPESCRIPT)
      console.log("Hello, world!");
    TYPESCRIPT

    run_generator

    assert_file "app/javascript/entrypoints/application.ts" do |content|
      assert_match(/import { Application as LiveComponentApplication }/, content)
      assert_match(/console\.log/, content)
    end
  end

  test "does not modify entrypoint if already configured" do
    create_entrypoint("app/javascript/entrypoints/application.ts", <<~TYPESCRIPT)
      import { Application as LiveComponentApplication } from "@camertron/live-component";
      import { Application as StimulusApplication } from "@hotwired/stimulus";

      window.Stimulus = StimulusApplication.start();
      window.Live = LiveComponentApplication.start(window.Stimulus);
    TYPESCRIPT

    run_generator

    assert_file "app/javascript/entrypoints/application.ts" do |content|
      import_count = content.scan(/import { Application as LiveComponentApplication }/).count
      assert_equal 1, import_count, "Should not duplicate imports"
    end
  end

  private

  def create_package_lock_file(filename)
    FileUtils.mkdir_p(destination_root)
    File.write(File.join(destination_root, filename), "")
  end

  def create_entrypoint(path, content)
    full_path = File.join(destination_root, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end
end
