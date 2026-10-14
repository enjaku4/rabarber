# frozen_string_literal: true

module Rabarber
  module Roleable
    extend ActiveSupport::Concern

    included do
      raise Rabarber::Error, "Rabarber::Roleable can only be included once" if defined?(@@included) && @@included != name

      @@included = name

      has_and_belongs_to_many :rabarber_roles, class_name: "Rabarber::Role",
                                               foreign_key: "roleable_id",
                                               join_table: "rabarber_roles_roleables"

      scope :with_role, -> (*role_names, context: nil) {
        joins(:rabarber_roles).where(
          rabarber_roles: { name: Rabarber::Inputs::Roles.new(role_names).process, **Rabarber::Inputs::Context.new(context).resolve }
        ).distinct
      }
    end

    def roles(context: nil)
      processed_context = Rabarber::Inputs::Context.new(context).resolve
      Rabarber::Core::Cache.fetch(roleable_id, processed_context) { rabarber_roles.list(context: processed_context) }
    end

    def all_roles
      Rabarber::Core::Cache.fetch(roleable_id, :all) { rabarber_roles.list_all }
    end

    def has_role?(*role_names, context: nil)
      processed_context = Rabarber::Inputs::Context.new(context).resolve
      processed_roles = Rabarber::Inputs::Roles.new(role_names).process
      roles(context: processed_context).intersect?(processed_roles)
    end

    def assign_roles(*role_names, context: nil, create_new: true)
      processed_role_names = Rabarber::Inputs::Roles.new(role_names).process
      processed_context = Rabarber::Inputs::Context.new(context).resolve

      create_new_roles(processed_role_names, context: processed_context) if create_new

      roles_to_assign = Rabarber::Role.where(
        name: (processed_role_names - rabarber_roles.list(context: processed_context)), **processed_context
      )

      if roles_to_assign.any?
        begin
          rabarber_roles << roles_to_assign
        rescue ActiveRecord::RecordNotUnique
          rabarber_roles.reset
        end
        delete_roleable_cache(contexts: [processed_context])
      end

      roles(context: processed_context)
    end

    def revoke_roles(*role_names, context: nil)
      processed_role_names = Rabarber::Inputs::Roles.new(role_names).process
      processed_context = Rabarber::Inputs::Context.new(context).resolve

      roles_to_revoke = Rabarber::Role.where(
        name: processed_role_names.intersection(rabarber_roles.list(context: processed_context)), **processed_context
      )

      if roles_to_revoke.any?
        self.rabarber_roles -= roles_to_revoke
        delete_roleable_cache(contexts: [processed_context])
      end

      roles(context: processed_context)
    end

    def revoke_all_roles
      return [] if rabarber_roles.none?

      contexts = all_roles.keys.map { Rabarber::Inputs::Context.new(_1).resolve }

      rabarber_roles.clear

      delete_roleable_cache(contexts:)

      []
    end

    private

    def create_new_roles(role_names, context:)
      new_roles = role_names - Rabarber.roles(context:)
      new_roles.each { |role_name| Rabarber::Role.register(role_name, context:) }
    end

    def delete_roleable_cache(contexts:)
      Rabarber::Core::Cache.delete(*contexts.map { [roleable_id, _1] }, [roleable_id, :all])
    end

    def roleable_id
      public_send(self.class.primary_key)
    end
  end
end
