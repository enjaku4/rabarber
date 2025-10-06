# frozen_string_literal: true

require "rails/railtie"

module Rabarber
  class Railtie < Rails::Railtie
    initializer "rabarber.to_prepare" do |app|
      app.config.to_prepare do
        ActiveRecord::Base.with_connection do |connection|
          if connection.data_source_exists?("rabarber_roles")
            Rabarber::Role.where.not(context_type: nil).distinct.pluck(:context_type).each do |context_class|
              context_class.constantize
            rescue NameError => e
              raise Rabarber::Error, "Context not found: class `#{e.name}` may have been renamed or deleted"
            end
          end
        rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
          # Database does not exist yet or connection not established, skip
        end

        Rabarber::Core::Permissions.reset! unless app.config.eager_load

        user_model = Rabarber::Configuration.user_model
        user_model.include Rabarber::Roleable unless user_model < Rabarber::Roleable
      end
    end

    initializer "rabarber.extend_migration_helpers" do
      ActiveSupport.on_load :active_record do
        ActiveRecord::Migration.include Rabarber::MigrationHelpers
      end
    end
  end
end
