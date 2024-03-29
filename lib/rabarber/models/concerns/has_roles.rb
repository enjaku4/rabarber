# frozen_string_literal: true

module Rabarber
  module HasRoles
    extend ActiveSupport::Concern

    included do
      raise Rabarber::Error, "Rabarber::HasRoles can only be included once" if defined?(@@included) && @@included != name

      @@included = name

      has_and_belongs_to_many :rabarber_roles, class_name: "Rabarber::Role",
                                               foreign_key: "roleable_id",
                                               join_table: "rabarber_roles_roleables"
    end

    def roles
      Rabarber::Cache.fetch(roleable_id) { rabarber_roles.names }
    end

    def has_role?(*role_names)
      roles.intersect?(process_role_names(role_names))
    end

    def assign_roles(*role_names, create_new: true)
      processed_role_names = process_role_names(role_names)

      create_new_roles(processed_role_names) if create_new

      roles_to_assign = Rabarber::Role.where(name: processed_role_names - rabarber_roles.names)

      if roles_to_assign.any?
        delete_roleable_cache
        rabarber_roles << roles_to_assign

        Rabarber::Audit::Events::RolesAssigned.trigger(self, roles_to_assign: roles_to_assign.names, current_roles: roles)
      end

      roles
    end

    def revoke_roles(*role_names)
      processed_role_names = process_role_names(role_names)
      roles_to_revoke = Rabarber::Role.where(name: processed_role_names.intersection(roles))

      if roles_to_revoke.any?
        delete_roleable_cache
        self.rabarber_roles -= roles_to_revoke

        Rabarber::Audit::Events::RolesRevoked.trigger(self, roles_to_revoke: roles_to_revoke.names, current_roles: roles)
      end

      roles
    end

    def roleable_class
      @@included.constantize
    end
    module_function :roleable_class

    private

    def create_new_roles(role_names)
      new_roles = role_names - Rabarber::Role.names
      new_roles.each { |role_name| Rabarber::Role.create!(name: role_name) }
    end

    def process_role_names(role_names)
      Rabarber::Input::Roles.new(role_names).process
    end

    def delete_roleable_cache
      Rabarber::Cache.delete(roleable_id)
    end

    def roleable_id
      public_send(self.class.primary_key)
    end
  end
end
