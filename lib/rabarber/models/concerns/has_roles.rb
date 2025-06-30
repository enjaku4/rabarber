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
      Rabarber::Core::Cache.fetch([roleable_id, processed_context]) { rabarber_roles.names(context: processed_context) }
    end

    def all_roles
      Rabarber::Core::Cache.fetch([roleable_id, :all]) { rabarber_roles.all_names }
    end

    def has_role?(*role_names, context: nil)
      processed_context = process_context(context)
      processed_roles = process_role_names(role_names)
      roles(context: processed_context).any? { |role_name| processed_roles.include?(role_name) }
    end

    def assign_roles(*role_names, context: nil, create_new: true)
      processed_role_names = process_role_names(role_names)
      processed_context = process_context(context)

      create_new_roles(processed_role_names, context: processed_context) if create_new

      roles_to_assign = Rabarber::Role.where(
        name: (processed_role_names - rabarber_roles.names(context: processed_context)), **processed_context
      )

      if roles_to_assign.any?
        delete_roleable_cache(contexts: [processed_context])
        rabarber_roles << roles_to_assign
      end

      roles(context: processed_context)
    end

    def revoke_roles(*role_names, context: nil)
      processed_role_names = process_role_names(role_names)
      processed_context = process_context(context)

      roles_to_revoke = Rabarber::Role.where(
        name: processed_role_names.intersection(rabarber_roles.names(context: processed_context)), **processed_context
      )

      if roles_to_revoke.any?
        delete_roleable_cache(contexts: [processed_context])
        self.rabarber_roles -= roles_to_revoke
      end

      roles(context: processed_context)
    end

    def revoke_all_roles
      return if rabarber_roles.none?

      contexts = all_roles.keys.map { process_context(_1) }

      rabarber_roles.clear

      delete_roleable_cache(contexts:)
    end

    private

    def create_new_roles(role_names, context:)
      new_roles = role_names - Rabarber::Role.names(context:)
      new_roles.each { |role_name| Rabarber::Role.create!(name: role_name, **context) }
    end

    def process_role_names(role_names)
      Rabarber::Inputs.process(
        role_names,
        as: :roles,
        message: "Expected an array of symbols or strings containing only lowercase letters, numbers, and underscores, got #{role_names.inspect}"
      )
    end

    def process_context(context)
      Rabarber::Inputs.process(context, as: :context, message: "Expected an instance of ActiveRecord model, a Class, or nil, got #{context.inspect}")
    end

    def delete_roleable_cache(contexts:)
      Rabarber::Core::Cache.delete(*contexts.map { [roleable_id, _1] }, [roleable_id, :all])
    end

    def roleable_id
      public_send(self.class.primary_key)
    end
  end
end
