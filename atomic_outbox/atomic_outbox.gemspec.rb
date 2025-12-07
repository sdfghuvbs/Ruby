# frozen_string_literal: true

require_relative 'lib/atomic_outbox/version'

Gem::Specification.new do |spec|
  spec.name          = "atomic_outbox"
  spec.version       = AtomicOutbox::VERSION
  spec.authors       = ["Your Name"]
  spec.email         = ["you@example.com"]
  spec.summary       = "Outbox Pattern implementation for Ruby applications."
  spec.description   = "Ensures transactional atomicity between state changes and event publishing."
  spec.homepage      = "https://example.com"
  spec.license       = "MIT"

  spec.files         = Dir.glob("lib/**/*.rb")
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", "~> 7.0"
  spec.add_dependency "json", "~> 2.6"
end