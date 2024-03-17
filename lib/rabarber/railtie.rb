# frozen_string_literal: true

require "rails/railtie"

module Rabarber
  class Railtie < Rails::Railtie
    initializer "rabarber.after_initialize" do |app|
      app.config.after_initialize do
        Rabarber::Missing::Actions.new.handle
        Rabarber::Missing::Roles.new.handle if Rabarber::Role.table_exists?

        Rabarber::Logger.log(
          :warn,
          "DEPRECATION WARNING: Configurations 'when_actions_missing' and 'when_roles_missing' are deprecated and will be removed in v2.0.0"
        )
      end
    end
  end
end
