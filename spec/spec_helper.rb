# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "byebug"
require "rabarber"
require "database_cleaner/active_record"
require "action_controller/railtie"
require "rspec/rails"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"

  config.disable_monkey_patching!

  config.expose_dsl_globally = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
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

if ENV["UUID_TESTS"]
  load "#{File.dirname(__FILE__)}/support/uuid_schema.rb"
else
  load "#{File.dirname(__FILE__)}/support/id_schema.rb"
end

require "#{File.dirname(__FILE__)}/support/models"
require "#{File.dirname(__FILE__)}/support/application"
require "#{File.dirname(__FILE__)}/support/controllers"
require "#{File.dirname(__FILE__)}/support/helpers"

if ENV["UUID_TESTS"]
  require "securerandom"

  ActiveSupport.on_load(:active_record) do
    [Rabarber::Role, User, Client, Project].each do |model_class|
      model_class.before_create do
        self.id = SecureRandom.uuid if id.blank?
      end
    end
  end
end
