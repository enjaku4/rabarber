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

    def roles(context: nil)
      processed_context = process_context(context)
      Rabarber::Core::Cache.fetch(roleable_id, context: processed_context) do
        rabarber_roles.where(processed_context.to_h).names
      end
    end

    def has_role?(*role_names, context: nil)
      roles(context: context).intersection(process_role_names(role_names)).any?
    end

    def assign_roles(*role_names, context: nil, create_new: true)
      processed_role_names = process_role_names(role_names)
      processed_context = process_context(context)

      create_new_roles(processed_role_names, processed_context) if create_new

      roles_to_assign = Rabarber::Role.where(
        name: (processed_role_names - rabarber_roles.where(processed_context.to_h).names),
        **processed_context.to_h
      )

      if roles_to_assign.any?
        delete_roleable_cache(processed_context)
        rabarber_roles << roles_to_assign

        Rabarber::Audit::Events::RolesAssigned.trigger(
          self, context: processed_context, roles_to_assign: roles_to_assign.names, current_roles: roles(context: context)
        )
      end

      roles(context: context)
    end

    def revoke_roles(*role_names, context: nil)
      processed_role_names = process_role_names(role_names)
      processed_context = process_context(context)

      roles_to_revoke = Rabarber::Role.where(
        name: processed_role_names.intersection(roles(context: context)),
        **processed_context.to_h
      )

      if roles_to_revoke.any?
        delete_roleable_cache(processed_context)
        self.rabarber_roles -= roles_to_revoke

        Rabarber::Audit::Events::RolesRevoked.trigger(
          self, context: processed_context, roles_to_revoke: roles_to_revoke.names, current_roles: roles(context: context)
        )
      end

      roles(context: context)
    end

    def roleable_class
      @@included.constantize
    end
    module_function :roleable_class

    private

    def create_new_roles(role_names, context)
      new_roles = role_names - Rabarber::Role.where(context.to_h).names
      new_roles.each { |role_name| Rabarber::Role.create!(name: role_name, **context.to_h) }
    end

    def process_context(context)
      Rabarber::Core::Context.new(context)
    end

    def process_role_names(role_names)
      Rabarber::Input::Roles.new(role_names).process
    end

    def delete_roleable_cache(context)
      Rabarber::Core::Cache.delete(roleable_id, context: context)
    end

    def roleable_id
      public_send(self.class.primary_key)
    end
  end
end
