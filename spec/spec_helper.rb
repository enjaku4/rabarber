# frozen_string_literal: true

require "byebug"
require "rabarber"
require "database_cleaner/active_record"
require "action_controller/railtie"
require "rspec/rails"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"

  config.expose_dsl_globally = true

  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
  end

  ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

  config.before(:suite) do
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around do |example|
    Rabarber::Configuration.reset_to_defaults!

    DatabaseCleaner.cleaning do
      example.run
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
