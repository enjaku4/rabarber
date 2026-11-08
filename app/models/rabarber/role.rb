# frozen_string_literal: true

module Rabarber
  class Role < ActiveRecord::Base
    self.table_name = "rabarber_roles"

    belongs_to :context, polymorphic: true, optional: true

    has_many :role_assignments, class_name: "Rabarber::RoleAssignment", inverse_of: :role, dependent: :delete_all

    class << self
      def list(context: nil)
        names_in(Rabarber::Inputs::Context.new(context).resolve)
      end

      def list_all
        roles = where(context_id: nil).to_a + where.not(context_id: nil).includes(:context).to_a

        roles.each_with_object({}) do |role, hash|
          (hash[role.context] ||= []) << role.name.to_sym
        rescue ActiveRecord::RecordNotFound
          next
        end
      rescue NameError => e
        raise Rabarber::NotFoundError, "Context not found: class `#{e.name}` may have been renamed or deleted"
      end

      def register(name, context: nil)
        register_in(Rabarber::Inputs::Role.new(name).process, Rabarber::Inputs::Context.new(context).resolve)
      end

      def amend(old_name, new_name, context: nil, force: false)
        processed_force = Rabarber::Inputs::Boolean.new(force).process
        processed_context = Rabarber::Inputs::Context.new(context).resolve
        role = find_by(name: Rabarber::Inputs::Role.new(old_name).process, **processed_context)

        raise Rabarber::NotFoundError, "Role not found" unless role

        name = Rabarber::Inputs::Role.new(new_name).process

        return false if exists?(name:, **processed_context) || role.role_assignments.exists? && !processed_force

        role.update!(name:)

        delete_roleables_cache(role.role_assignments.pluck(:roleable_id), context: processed_context)

        true
      rescue ActiveRecord::RecordNotUnique
        false
      end

      def drop(name, context: nil, force: false)
        processed_force = Rabarber::Inputs::Boolean.new(force).process
        processed_context = Rabarber::Inputs::Context.new(context).resolve
        role = find_by(name: Rabarber::Inputs::Role.new(name).process, **processed_context)

        raise Rabarber::NotFoundError, "Role not found" unless role

        return false if role.role_assignments.exists? && !processed_force

        roleable_ids = role.role_assignments.pluck(:roleable_id)

        role.destroy!

        delete_roleables_cache(roleable_ids, context: processed_context)

        true
      end

      def prune
        where.not(context_id: nil).distinct.pluck(:context_type).each do |context_type|
          context_class = context_type.safe_constantize

          raise Rabarber::NotFoundError, "Context not found: class `#{context_type}` may have been renamed or deleted" unless context_class

          delete_with_assignments(where(context_type:).where.not(context_id: context_class.select(context_class.primary_key)))
        end

        Rabarber::Core::Cache.clear
      end

      def names_in(processed_context)
        where(processed_context).pluck(:name).map(&:to_sym)
      end

      def register_in(name, processed_context)
        return false if exists?(name:, **processed_context)

        !!create!(name:, **processed_context)
      rescue ActiveRecord::RecordNotUnique
        false
      end

      def delete_with_assignments(roles)
        transaction do
          Rabarber::RoleAssignment.where(role: roles).delete_all
          roles.delete_all
        end
      end

      private

      def delete_roleables_cache(roleable_ids, context:)
        Rabarber::Core::Cache.delete(*roleable_ids.flat_map { [[_1, context], [_1, :all]] })
      end
    end

    def context
      return context_type.constantize if context_type.present? && context_id.blank?

      record = super

      raise ActiveRecord::RecordNotFound.new(nil, context_type, nil, context_id) if context_id.present? && !record

      record
    end
  end
end
