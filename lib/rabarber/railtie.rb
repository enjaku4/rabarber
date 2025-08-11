# frozen_string_literal: true

require "rails/railtie"

module Rabarber
  class Railtie < Rails::Railtie
    initializer "rabarber.to_prepare" do |app|
      app.config.to_prepare do
        Rabarber::Core::IntegrityChecker.run!
        Rabarber::Core::Permissions.reset! unless app.config.eager_load
        user_model = Rabarber::Configuration.user_model
        user_model.include Rabarber::HasRoles unless user_model < Rabarber::HasRoles
      end
    end

    initializer "rabarber.extend_migration_helpers" do
      ActiveSupport.on_load :active_record do
        ActiveRecord::Migration.include Rabarber::MigrationHelpers
      end
    end
  end
end
