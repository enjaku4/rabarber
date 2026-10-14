# frozen_string_literal: true

require "rails/railtie"

module Rabarber
  class Railtie < Rails::Railtie
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

        Rabarber::Role.send(:remove_const, :HABTM_Roleables) if Rabarber::Role.const_defined?(:HABTM_Roleables, false)
        Rabarber::Role.has_and_belongs_to_many :roleables, class_name: Rabarber::Configuration.user_model_name,
                                                           association_foreign_key: "roleable_id",
                                                           join_table: "rabarber_roles_roleables"
      end
    end

    initializer "rabarber.extend_migration_helpers" do
      ActiveSupport.on_load :active_record do
        ActiveRecord::Migration.include Rabarber::MigrationHelpers
      end
    end
  end
end
