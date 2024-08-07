# frozen_string_literal: true

require_relative "lib/rabarber/version"

Gem::Specification.new do |spec|
  spec.name = "rabarber"
  spec.version = Rabarber::VERSION
  spec.authors = ["enjaku4", "trafium"]
  spec.email = ["rabarber_gem@icloud.com"]
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.summary = "Simple role-based authorization library for Ruby on Rails."
  spec.homepage = "https://github.com/enjaku4/rabarber"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0", "< 3.4"

  spec.files = [
    "rabarber.gemspec", "README.md", "CHANGELOG.md", "LICENSE.txt"
  ] + `git ls-files | grep -E '^(lib)'`.split("\n")

  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 6.1", "< 7.2"
end
