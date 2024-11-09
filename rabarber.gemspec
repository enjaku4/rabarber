# frozen_string_literal: true

require_relative "lib/rabarber/version"

Gem::Specification.new do |spec|
  spec.name = "rabarber"
  spec.version = Rabarber::VERSION
  spec.authors = ["enjaku4", "trafium"]
  spec.email = ["rabarber_gem@icloud.com"]
  spec.homepage = "https://github.com/enjaku4/rabarber"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.summary = "Simple role-based authorization library for Ruby on Rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1", "< 3.4"

  spec.files = [
    "rabarber.gemspec", "README.md", "CHANGELOG.md", "LICENSE.txt"
  ] + `git ls-files | grep -E '^(lib)'`.split("\n")

  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.0", "< 8.1"
end
