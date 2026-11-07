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
      cached_roles(Rabarber::Inputs::Context.new(context).resolve)
    end

    def all_roles
      Rabarber::Core::Cache.fetch(id, :all) { rabarber_roles.list_all }
    end

    def has_role?(*role_names, context: nil)
      processed_context = Rabarber::Inputs::Context.new(context).resolve
      processed_roles = Rabarber::Inputs::Roles.new(role_names).process
      cached_roles(processed_context).intersect?(processed_roles)
    end

    def assign_roles(*role_names, context: nil, create_new: true)
      unsaved_user_deprecation_warning("assign_roles")

      processed_role_names = Rabarber::Inputs::Roles.new(role_names).process
      processed_context = Rabarber::Inputs::Context.new(context).resolve
      processed_create_new = Rabarber::Inputs::Boolean.new(create_new).process

      Rabarber::Role.insert_missing(processed_role_names, processed_context) if processed_create_new

      role_ids = Rabarber::Role.where(
        name: (processed_role_names - rabarber_roles.names_in(processed_context)), **processed_context
      ).ids

      if role_ids.any?
        if persisted?
          Rabarber::RoleAssignment.insert_all(role_ids.map { { role_id: _1, roleable_id: id } })
          rabarber_roles.reset
        else
          rabarber_roles << Rabarber::Role.where(id: role_ids)
        end

        delete_roleable_cache(contexts: [processed_context])
      end

      cached_roles(processed_context)
    end

    def revoke_roles(*role_names, context: nil)
      unsaved_user_deprecation_warning("revoke_roles")

      processed_role_names = Rabarber::Inputs::Roles.new(role_names).process
      processed_context = Rabarber::Inputs::Context.new(context).resolve

      role_ids = Rabarber::Role.where(name: processed_role_names, **processed_context).ids

      if Rabarber::RoleAssignment.where(roleable_id: id, role_id: role_ids).delete_all.positive?
        rabarber_roles.reset
        delete_roleable_cache(contexts: [processed_context])
      end

      cached_roles(processed_context)
    end

    def revoke_all_roles
      unsaved_user_deprecation_warning("revoke_all_roles")

      return [] if rabarber_roles.none?

      contexts = all_roles.keys.map { Rabarber::Inputs::Context.new(_1).resolve }

      rabarber_roles.clear

      delete_roleable_cache(contexts:)

      []
    end

    private

    def cached_roles(processed_context)
      Rabarber::Core::Cache.fetch(id, processed_context) { rabarber_roles.names_in(processed_context) }
    end

    def delete_roleable_cache(contexts:)
      Rabarber::Core::Cache.delete(*contexts.map { [id, _1] }, [id, :all])
    end

    def unsaved_user_deprecation_warning(method_name)
      return if persisted?

      Rabarber.deprecator.warn("Calling `#{method_name}` on an unsaved user is deprecated and will raise an error in the next major version, save the user first", caller_locations(2))
    end
  end
end
