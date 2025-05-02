# frozen_string_literal: true

require "rails/railtie"

module Rabarber
  class Railtie < Rails::Railtie
    initializer "rabarber.to_prepare" do |app|
      app.config.to_prepare do
        Rabarber::Core::Permissions.reset! unless app.config.eager_load
        user_model = Rabarber::Configuration.instance.user_model
        user_model.include Rabarber::HasRoles unless user_model < Rabarber::HasRoles
      end
    end

    initializer "rabarber.after_initialize" do |app|
      app.config.after_initialize do
        Rabarber::Core::IntegrityChecker.run! if app.config.eager_load
      end
    end
  end
end
