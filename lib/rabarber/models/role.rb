# frozen_string_literal: true

module Rabarber
  class Role < ActiveRecord::Base
    self.table_name = "rabarber_roles"

    belongs_to :context, polymorphic: true, optional: true

    class << self
      def list(context: nil)
        where(Rabarber::Inputs::Context.new(context).resolve).pluck(:name).map(&:to_sym)
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
        name = Rabarber::Inputs::Role.new(name).process
        processed_context = Rabarber::Inputs::Context.new(context).resolve

        return false if exists?(name:, **processed_context)

        !!create!(name:, **processed_context)
      rescue ActiveRecord::RecordNotUnique
        false
      end

      def amend(old_name, new_name, context: nil, force: false)
        processed_context = Rabarber::Inputs::Context.new(context).resolve
        role = find_by(name: Rabarber::Inputs::Role.new(old_name).process, **processed_context)

        raise Rabarber::NotFoundError, "Role not found" unless role

        name = Rabarber::Inputs::Role.new(new_name).process

        return false if exists?(name:, **processed_context) || role.roleables.exists? && !force

        role.update!(name:)

        delete_roleables_cache(role.roleables.pluck(:id), context: processed_context)

        true
      rescue ActiveRecord::RecordNotUnique
        false
      end

      def drop(name, context: nil, force: false)
        processed_context = Rabarber::Inputs::Context.new(context).resolve
        role = find_by(name: Rabarber::Inputs::Role.new(name).process, **processed_context)

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
    end

    def context
      return context_type.constantize if context_type.present? && context_id.blank?

      record = super

      raise ActiveRecord::RecordNotFound.new(nil, context_type, nil, context_id) if context_id.present? && !record

      record
    end
  end
end
