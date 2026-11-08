# frozen_string_literal: true

require "rails/engine"

module Rabarber
  class Engine < Rails::Engine
    initializer "rabarber.include_roleable" do
      Rails.autoloaders.each do |autoloader|
        autoloader.on_load do |cpath, klass, _abspath|
          klass.include Rabarber::Roleable if cpath == Rabarber::Configuration.user_model_name
        end
      end
    end

    initializer "rabarber.to_prepare" do |app|
      app.config.to_prepare do
        Rabarber::Core::Permissions.reset! unless app.config.eager_load
      end
    end

    initializer "rabarber.deprecator" do |app|
      app.deprecators[:rabarber] = Rabarber.deprecator
    end

    initializer "rabarber.extend_migration_helpers" do
      ActiveSupport.on_load :active_record do
        ActiveRecord::Migration.include Rabarber::MigrationHelpers
      end
    end
  end
end
