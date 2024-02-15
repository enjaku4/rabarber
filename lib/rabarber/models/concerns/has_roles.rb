# frozen_string_literal: true

module Rabarber
  module HasRoles
    extend ActiveSupport::Concern

    included do
      if defined?(@@included) && @@included != name
        raise Rabarber::Error, "Rabarber::HasRoles can only be included once"
      end

      @@included = name

      has_and_belongs_to_many :rabarber_roles, class_name: "Rabarber::Role",
                                               foreign_key: "roleable_id",
                                               join_table: "rabarber_roles_roleables"
    end

    def roles
      Rabarber::Cache.fetch(Rabarber::Cache.key_for(self), expires_in: 1.hour, race_condition_ttl: 5.seconds) do
        rabarber_roles.names
      end
    end

    def has_role?(*role_names)
      (roles & process_role_names(role_names)).any?
    end

    # TODO: test return value
    def assign_roles(*role_names, create_new: true)
      delete_cache

      roles_to_assign = process_role_names(role_names)

      create_new_roles(roles_to_assign) if create_new

      rabarber_roles << Rabarber::Role.where(name: roles_to_assign) - rabarber_roles

      roles
    end

    # TODO: test return value
    def revoke_roles(*role_names)
      delete_cache

      self.rabarber_roles = rabarber_roles - Rabarber::Role.where(name: process_role_names(role_names))

      roles
    end

    private

    def create_new_roles(role_names)
      new_roles = role_names - Rabarber::Role.names
      new_roles.each { |role_name| Rabarber::Role.add(role_name) }
    end

    def process_role_names(role_names)
      Rabarber::Input::Roles.new(role_names).process
    end

    def delete_cache
      Rabarber::Cache.delete(Rabarber::Cache.key_for(self))
    end
  end
end
