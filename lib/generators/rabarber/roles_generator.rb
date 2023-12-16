# frozen_string_literal: true

require "rails/generators/migration"

module Rabarber
  class RolesGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path("templates", __dir__)

    def create_migrations
      migration_template "create_rabarber_roles.rb.erb", "db/migrate/create_rabarber_roles.rb"
    end

    def self.next_migration_number(_path)
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    end
  end
end
