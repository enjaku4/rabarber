# frozen_string_literal: true

module Rabarber
  class Role < ActiveRecord::Base
    self.table_name = "rabarber_roles"

    belongs_to :context, polymorphic: true, optional: true

    has_and_belongs_to_many :roleables, class_name: Rabarber::Configuration.user_model_name, # rubocop:disable Rails/HasAndBelongsToMany
                                        association_foreign_key: "roleable_id",
                                        join_table: "rabarber_roles_roleables"

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

      def register(names, context: nil)
        processed_names = Rabarber::Inputs::Roles.new(names).process
        processed_context = Rabarber::Inputs::Context.new(context).resolve

        new_names = processed_names.uniq - list(context: processed_context)

        insert_all(new_names.map { { name: _1, **processed_context } }) if new_names.any?

        list(context: processed_context)
      end

      def amend(old_name, new_name, context: nil, force: false)
        processed_context = Rabarber::Inputs::Context.new(context).resolve
        processed_force = Rabarber::Inputs::Boolean.new(force).process
        role = find_by(name: Rabarber::Inputs::Role.new(old_name).process, **processed_context)

        raise Rabarber::NotFoundError, "Role not found" unless role

        name = Rabarber::Inputs::Role.new(new_name).process

        return false if exists?(name:, **processed_context) || role.roleables.exists? && !processed_force

        role.update!(name:)

        delete_roleables_cache(role.roleables.ids, context: processed_context)

        true
      rescue ActiveRecord::RecordNotUnique
        false
      end

      def drop(names, context: nil, force: false)
        processed_names = Rabarber::Inputs::Roles.new(names).process
        processed_context = Rabarber::Inputs::Context.new(context).resolve
        processed_force = Rabarber::Inputs::Boolean.new(force).process

        roles = where(name: processed_names, **processed_context)
        roles = roles.where.missing(:roleables) unless processed_force

        role_ids = roles.ids
        roleable_ids = Rabarber::Configuration.user_model.joins(:rabarber_roles).where(rabarber_roles: { id: role_ids }).distinct.ids

        delete_with_assignments(role_ids)

        delete_roleables_cache(roleable_ids, context: processed_context)

        list(context: processed_context)
      end

      def prune
        orphaned_roles = where.not(context_id: nil).distinct.pluck(:context_type).flat_map do |context_type|
          context_class = context_type.constantize
          where(context_type:).where.not(context_id: context_class.select(context_class.primary_key)).pluck(:id)
        end

        return if orphaned_roles.empty?

        delete_with_assignments(orphaned_roles)

        Rabarber::Core::Cache.clear
      end

      def deprecated_register(name, context: nil)
        name = Rabarber::Inputs::Role.new(name).process
        processed_context = Rabarber::Inputs::Context.new(context).resolve

        return false if exists?(name:, **processed_context)

        !!create!(name:, **processed_context)
      rescue ActiveRecord::RecordNotUnique
        false
      end

      def deprecated_drop(name, context: nil, force: false)
        processed_context = Rabarber::Inputs::Context.new(context).resolve
        processed_force = Rabarber::Inputs::Boolean.new(force).process
        role = find_by(name: Rabarber::Inputs::Role.new(name).process, **processed_context)

        raise Rabarber::NotFoundError, "Role not found" unless role

        return false if role.roleables.exists? && !processed_force

        roleable_ids = role.roleables.ids

        role.destroy!

        delete_roleables_cache(roleable_ids, context: processed_context)

        true
      end

      def delete_with_assignments(role_ids)
        transaction do
          with_connection do |connection|
            connection.execute(sanitize_sql(["DELETE FROM rabarber_roles_roleables WHERE role_id IN (?)", role_ids]))
          end
          where(id: role_ids).delete_all
        end
      end

      def insert_assignments(roleable_id, role_ids)
        with_connection do |connection|
          connection.execute(sanitize_sql(["INSERT INTO rabarber_roles_roleables (role_id, roleable_id) SELECT id, ? FROM rabarber_roles WHERE id IN (?)", roleable_id, role_ids]))
        end
      rescue ActiveRecord::RecordNotUnique
        nil
      end

      def delete_assignments(roleable_id, role_ids)
        with_connection do |connection|
          connection.delete(sanitize_sql(["DELETE FROM rabarber_roles_roleables WHERE roleable_id = ? AND role_id IN (?)", roleable_id, role_ids]))
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
