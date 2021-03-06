# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "aggregated_record/version"

Gem::Specification.new do |spec|
  spec.name          = "aggregated_record"
  spec.version       = AggregatedRecord::VERSION
  spec.authors       = ["Emerson Almeida"]
  spec.email         = ["emerson@megafono.host"]

  spec.summary       = "Helping you to build record from a event sourcing project using RailsEventStore"
  spec.description   = "Helping you to build record from a event sourcing project using RailsEventStore"
  spec.homepage      = "https://github.com/megafono/aggregate_record"
  spec.license       = "MIT"

  if spec.respond_to?(:metadata)
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = spec.homepage
    spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "aggregate_root"
  spec.add_runtime_dependency "zeitwerk"
  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "activemodel"

  spec.add_development_dependency "byebug"
  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "test-unit"
end
