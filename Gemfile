# frozen_string_literal: true

source "https://rubygems.org"

gemspec

rails_version = ENV.fetch("RAILS_VERSION", ">= 7.0")

gem "byebug"
gem "database_cleaner-active_record"
gem "grepfruit"
gem "rails", rails_version
gem "rake"
gem "rspec"
gem "rspec-rails"
gem "rubocop"
gem "rubocop-performance"
gem "rubocop-rails"
gem "rubocop-rake"
gem "rubocop-rspec"
gem "rubocop-rspec_rails"
gem "rubocop-thread_safety"
gem "sqlite3", rails_version.to_i < 8 ? "~> 1.4" : ">= 2.1"
