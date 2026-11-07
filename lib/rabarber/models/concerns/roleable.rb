# frozen_string_literal: true

module Rabarber
  module Roleable
    extend ActiveSupport::Concern

    included do
      raise Rabarber::Error, "Rabarber::Roleable can only be included once" if defined?(@@included) && @@included != name

      @@included = name

      has_many :rabarber_role_assignments, class_name: "Rabarber::RoleAssignment", foreign_key: "roleable_id", inverse_of: :roleable, dependent: :delete_all
      has_many :rabarber_roles, through: :rabarber_role_assignments, source: :role

      scope :with_role, -> (*role_names, context: nil) {
        joins(:rabarber_roles).where(
          rabarber_roles: { name: Rabarber::Inputs::Roles.new(role_names).process, **Rabarber::Inputs::Context.new(context).resolve }
        ).distinct
      }
    end

    def roles(context: nil)
      processed_context = Rabarber::Inputs::Context.new(context).resolve
      Rabarber::Core::Cache.fetch(id, processed_context) { rabarber_roles.list(context: processed_context) }
    end

    def all_roles
      Rabarber::Core::Cache.fetch(id, :all) { rabarber_roles.list_all }
    end

    def has_role?(*role_names, context: nil)
      processed_context = Rabarber::Inputs::Context.new(context).resolve
      processed_roles = Rabarber::Inputs::Roles.new(role_names).process
      roles(context: processed_context).intersect?(processed_roles)
    end

    def assign_roles(*role_names, context: nil, create_new: true)
      processed_create_new = Rabarber::Inputs::Boolean.new(create_new).process
      warn_if_unsaved_roleable(:assign_roles)

      processed_role_names = Rabarber::Inputs::Roles.new(role_names).process
      processed_context = Rabarber::Inputs::Context.new(context).resolve

      create_new_roles(processed_role_names, context: processed_context) if processed_create_new

      role_ids = Rabarber::Role.where(
        name: (processed_role_names - rabarber_roles.list(context: processed_context)), **processed_context
      ).ids

      if role_ids.any?
        if persisted?
          rabarber_role_assignments.insert_all(role_ids.map { { role_id: _1 } })
          rabarber_roles.reset
        else
          rabarber_roles << Rabarber::Role.where(id: role_ids)
        end
        delete_roleable_cache(contexts: [processed_context])
      end

      roles(context: processed_context)
    end

    def revoke_roles(*role_names, context: nil)
      warn_if_unsaved_roleable(:revoke_roles)

      processed_role_names = Rabarber::Inputs::Roles.new(role_names).process
      processed_context = Rabarber::Inputs::Context.new(context).resolve

      if rabarber_role_assignments.where(role: Rabarber::Role.where(name: processed_role_names, **processed_context)).delete_all.positive?
        rabarber_roles.reset
        delete_roleable_cache(contexts: [processed_context])
      end

      roles(context: processed_context)
    end

    def revoke_all_roles
      warn_if_unsaved_roleable(:revoke_all_roles)

      contexts = rabarber_roles.distinct.pluck(:context_type, :context_id).map { |context_type, context_id| { context_type:, context_id: } }

      rabarber_role_assignments.delete_all
      rabarber_roles.reset

      delete_roleable_cache(contexts:) if contexts.any?

      []
    end

    private

    def warn_if_unsaved_roleable(method_name)
      return unless new_record?

      Rabarber.deprecator.warn(
        "Calling ##{method_name} on an unsaved record is deprecated. Save the record before managing roles."
      )
    end

    def create_new_roles(role_names, context:)
      new_roles = role_names - Rabarber.roles(context:)
      new_roles.each { |role_name| Rabarber::Role.register(role_name, context:) }
    end

    def delete_roleable_cache(contexts:)
      Rabarber::Core::Cache.delete(*contexts.map { [id, _1] }, [id, :all])
    end
  end
end
