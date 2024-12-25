# frozen_string_literal: true

require "rails/railtie"

module Rabarber
  class Railtie < Rails::Railtie
    initializer "rabarber.after_initialize" do |app|
      app.config.after_initialize do
        Rabarber::Core::Cache.clear
        Rabarber::Core::PermissionsIntegrityChecker.new.run! if app.config.eager_load
      end
    end
  end
end
