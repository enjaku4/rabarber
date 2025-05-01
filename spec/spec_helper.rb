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

  config.expose_dsl_globally = true

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
    end

    reset_config = Rabarber::Configuration.send(:new)

    Rabarber::Configuration.instance.instance_variables.each do |var|
      Rabarber::Configuration.instance.instance_variable_set(var, reset_config.instance_variable_get(var))
    end
  end
end

load "#{File.dirname(__FILE__)}/support/schema.rb"

require "#{File.dirname(__FILE__)}/support/models"
require "#{File.dirname(__FILE__)}/support/application"
require "#{File.dirname(__FILE__)}/support/controllers"
require "#{File.dirname(__FILE__)}/support/helpers"
