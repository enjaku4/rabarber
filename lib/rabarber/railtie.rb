# frozen_string_literal: true

require "rails/railtie"

module Rabarber
  class Railtie < Rails::Railtie
    initializer "rabarber.to_prepare" do |app|
      app.config.to_prepare do
        user_model = Rabarber::Configuration.instance.user_model
        user_model.include Rabarber::HasRoles unless user_model < Rabarber::HasRoles
        Rabarber::Core::IntegrityChecker.run!
      end
    end
  end
end
