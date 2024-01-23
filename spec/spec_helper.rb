# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "byebug"
require "rabarber"
require "database_cleaner/active_record"
require "action_controller/railtie"
require "rspec/rails"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around do |example|
    DatabaseCleaner.cleaning do
      example.run
      reset_config = Rabarber::Configuration.send(:new)
      Rabarber::Configuration.instance.current_user_method = reset_config.current_user_method
      Rabarber::Configuration.instance.must_have_roles = reset_config.must_have_roles
      Rabarber::Configuration.instance.when_unauthorized = reset_config.when_unauthorized
    end
  end
end

load "#{File.dirname(__FILE__)}/support/schema.rb"

require "#{File.dirname(__FILE__)}/support/application"
require "#{File.dirname(__FILE__)}/support/controllers"
require "#{File.dirname(__FILE__)}/support/helpers"
require "#{File.dirname(__FILE__)}/support/models"
