# frozen_string_literal: true

source "https://rubygems.org"

gemspec

rails_version = ENV.fetch("RAILS_VERSION", "~> 7")

gem "byebug"
gem "concurrent-ruby", "1.3.4"
gem "database_cleaner-active_record"
gem "grepfruit"
gem "rails", rails_version
gem "rake"
gem "rspec"
gem "rspec-rails"
gem "rubocop"
gem "rubocop-md"
gem "rubocop-packaging"
gem "rubocop-performance"
gem "rubocop-rails"
gem "rubocop-rake"
gem "rubocop-rspec"
gem "rubocop-rspec_rails"
gem "rubocop-thread_safety"
gem "sqlite3", rails_version.match?(/(^8\.| 8\.)/) ? ">= 2.1" : "~> 1.4"
