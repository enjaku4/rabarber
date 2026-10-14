# frozen_string_literal: true

module Rabarber
  class Role < ActiveRecord::Base
    self.table_name = "rabarber_roles"

    belongs_to :context, polymorphic: true, optional: true

    class << self
      def list(context: nil)
        where(process_context(context)).pluck(:name).map(&:to_sym)
      end

      def list_all
        roles = where(context_id: nil).to_a + where.not(context_id: nil).includes(:context).to_a

        roles.each_with_object({}) do |role, hash|
          (hash[role.context] ||= []) << role.name.to_sym
        rescue ActiveRecord::RecordNotFound
          next
        end
      rescue NameError => e
        raise Rabarber::NotFoundError, "Context not found: class #{e.name} may have been renamed or deleted"
      end

      def register(name, context: nil)
        name = process_role_name(name)
        processed_context = process_context(context)

        return false if exists?(name:, **processed_context)

        !!create!(name:, **processed_context)
      rescue ActiveRecord::RecordNotUnique
        false
      end

      def amend(old_name, new_name, context: nil, force: false)
        processed_context = process_context(context)
        role = find_by(name: process_role_name(old_name), **processed_context)

        raise Rabarber::NotFoundError, "Role not found" unless role

        name = process_role_name(new_name)

        return false if exists?(name:, **processed_context) || role.roleables.exists? && !force

        role.update!(name:)

        delete_roleables_cache(role.roleables.pluck(:id), context: processed_context)

        true
      rescue ActiveRecord::RecordNotUnique
        false
      end

      def drop(name, context: nil, force: false)
        processed_context = process_context(context)
        role = find_by(name: process_role_name(name), **processed_context)

        raise Rabarber::NotFoundError, "Role not found" unless role

        return false if role.roleables.exists? && !force

        roleable_ids = role.roleables.pluck(:id)

        role.destroy!

        delete_roleables_cache(roleable_ids, context: processed_context)

        true
      end

      def prune
        orphaned_roles = where.not(context_id: nil).includes(:context).filter_map do |role|
          !role.context
        rescue ActiveRecord::RecordNotFound
          role.id
        end

        return if orphaned_roles.empty?

        ActiveRecord::Base.transaction do
          ActiveRecord::Base.connection.execute(
            ActiveRecord::Base.sanitize_sql(
              ["DELETE FROM rabarber_roles_roleables WHERE role_id IN (?)", orphaned_roles]
            )
          )
          where(id: orphaned_roles).delete_all
        end

        Rabarber::Core::Cache.clear
      end

      private

      def delete_roleables_cache(roleable_ids, context:)
        Rabarber::Core::Cache.delete(*roleable_ids.flat_map { [[_1, context], [_1, :all]] })
      end

      def process_role_name(name)
        Rabarber::Inputs::Role.new(
          name,
          message: "Expected a symbol or a string containing only lowercase letters, numbers, and underscores, got #{name.inspect}"
        ).process
      end

      def process_context(context)
        Rabarber::Inputs::Context.new(
          context,
          error: Rabarber::InvalidContextError,
          message: "Expected an instance of ActiveRecord model, a Class, or nil, got #{context.inspect}"
        ).resolve
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
