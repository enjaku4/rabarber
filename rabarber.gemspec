# frozen_string_literal: true

require_relative "lib/rabarber/version"

Gem::Specification.new do |spec|
  spec.name = "rabarber"
  spec.version = Rabarber::VERSION
  spec.authors = ["enjaku4", "trafium"]
  spec.homepage = "https://github.com/brownboxdev/rabarber"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.summary = "Simple role-based authorization library for Ruby on Rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2", "< 3.5"

  spec.files = [
    "rabarber.gemspec", "README.md", "CHANGELOG.md", "LICENSE.txt"
  ] + Dir.glob("lib/**/*")

  spec.require_paths = ["lib"]

  spec.add_dependency "dry-configurable", "~> 1.3"
  spec.add_dependency "dry-types", "~> 1.8"
  spec.add_dependency "rails", ">= 7.1", "< 8.1"
end
