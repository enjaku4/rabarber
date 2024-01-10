# frozen_string_literal: true

require_relative "lib/rabarber/version"

Gem::Specification.new do |spec|
  spec.name = "rabarber"
  spec.version = Rabarber::VERSION
  spec.authors = ["enjaku4", "trafium"]
  spec.email = ["enjaku4@gmail.com"]

  spec.summary = "Simple authorization library for Ruby on Rails."
  spec.homepage = "https://github.com/enjaku4/rabarber"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.files = [
    "rabarber.gemspec", "README.md", "CHANGELOG.md", "LICENSE.txt"
  ] + `git ls-files | grep -E '^(lib)'`.split("\n")

  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "rails", ">= 6.1"
end
