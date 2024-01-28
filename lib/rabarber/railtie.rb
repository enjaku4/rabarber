# frozen_string_literal: true

require "rails/railtie"

module Rabarber
  class Railtie < Rails::Railtie
    initializer "rabarber.after_initialize" do |app|
      app.config.after_initialize do
        Rabarber::Missing::Actions.new.handle
        Rabarber::Missing::Roles.new.handle
      end
    end
  end
end
