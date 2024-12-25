# frozen_string_literal: true

source "https://rubygems.org"

gemspec

rails_version = ENV.fetch("RAILS_VERSION", ">= 7.0")

# TODO: base64, bigdecimal, drb and mutex_m are likely not needed, wait for Rails patch release
gem "base64"
gem "bigdecimal"
gem "byebug"
gem "database_cleaner-active_record"
gem "drb"
gem "grepfruit"
gem "mutex_m"
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
gem "sqlite3", rails_version.match?(/(^8\.| 8\.)/) ? ">= 2.1" : "~> 1.4"
