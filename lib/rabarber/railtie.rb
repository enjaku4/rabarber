# frozen_string_literal: true

require "rails/railtie"

module Rabarber
  class Railtie < Rails::Railtie
    initializer "rabarber.after_initialize" do |app|
      app.config.after_initialize do
        # TODO: ensure user model doesn’t lose the module after a reload in dev mode
        Rabarber::Configuration.instance.user_model.include Rabarber::HasRoles
        Rabarber::Core::IntegrityChecker.new.run! if app.config.eager_load
      end
    end
  end
end
