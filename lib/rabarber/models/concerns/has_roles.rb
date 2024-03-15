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
      Rabarber::Cache.fetch(Rabarber::Cache.key_for(roleable_id), expires_in: 1.hour, race_condition_ttl: 5.seconds) do
        rabarber_roles.names
      end
    end

    def has_role?(*role_names)
      (roles & process_role_names(role_names)).any?
    end

    def assign_roles(*role_names, create_new: true)
      processed_role_names = process_role_names(role_names)

      create_new_roles(processed_role_names) if create_new

      roles_to_assign = Rabarber::Role.where(name: processed_role_names) - rabarber_roles

      if roles_to_assign.any?
        delete_roleable_cache
        rabarber_roles << roles_to_assign

        Rabarber::Logger.audit(
          :info,
          "[Role Assignment] #{Rabarber::Logger.roleable_identity(self, with_roles: false)} has been assigned the following roles: #{roles_to_assign.pluck(:name).map(&:to_sym)}, current roles: #{roles}"
        )
      end

      roles
    end

    def revoke_roles(*role_names)
      processed_role_names = process_role_names(role_names)
      roles_to_revoke = Rabarber::Role.where(name: processed_role_names.intersection(roles))

      if roles_to_revoke.any?
        delete_roleable_cache
        self.rabarber_roles -= roles_to_revoke

        Rabarber::Logger.audit(
          :info,
          "[Role Revocation] #{Rabarber::Logger.roleable_identity(self, with_roles: false)} has been revoked from the following roles: #{roles_to_revoke.pluck(:name).map(&:to_sym)}, current roles: #{roles}"
        )
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
      Rabarber::Cache.delete(Rabarber::Cache.key_for(roleable_id))
    end

    def roleable_id
      public_send(self.class.primary_key)
    end
  end
end
