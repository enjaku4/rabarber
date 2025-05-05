# frozen_string_literal: true

require "rails/railtie"

module Rabarber
  class Railtie < Rails::Railtie
    initializer "rabarber.to_prepare" do |app|
      app.config.to_prepare do
        unless app.config.eager_load
          Rabarber::Core::Permissions.reset!
          ApplicationController.class_eval do
            before_action :check_integrity

            private

            def check_integrity
              Rabarber::Core::IntegrityChecker.run!
            end
          end
        end
        user_model = Rabarber::Configuration.instance.user_model
        user_model.include Rabarber::HasRoles unless user_model < Rabarber::HasRoles
      end
    end

    initializer "rabarber.after_initialize" do |app|
      app.config.after_initialize do
        Rabarber::Core::IntegrityChecker.run! if app.config.eager_load
      end
    end

    initializer "rabarber.extend_migration_helpers" do
      ActiveSupport.on_load :active_record do
        ActiveRecord::Migration.include Rabarber::MigrationHelpers
      end
    end
  end
end
