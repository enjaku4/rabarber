# frozen_string_literal: true

module Rabarber
  class Role < ActiveRecord::Base
    self.table_name = "rabarber_roles"

    belongs_to :context, polymorphic: true, optional: true

    has_and_belongs_to_many :roleables, class_name: Rabarber::Configuration.user_model_name,
                                        association_foreign_key: "roleable_id",
                                        join_table: "rabarber_roles_roleables"

    class << self
      def names(context: nil)
        deprecation_warning("names", "Rabarber.roles")

        where(process_context(context)).pluck(:name).map(&:to_sym)
      end

      def all_names
        deprecation_warning("all_names", "Rabarber.all_roles")

        includes(:context).each_with_object({}) do |role, hash|
          (hash[role.context] ||= []) << role.name.to_sym
        rescue ActiveRecord::RecordNotFound
          next
        end
      rescue NameError => e
        raise Rabarber::NotFoundError, "Context not found: class #{e.name} may have been renamed or deleted"
      end

      def add(name, context: nil)
        deprecation_warning("add", "Rabarber.create_role")

        name = process_role_name(name)
        processed_context = process_context(context)

        return false if exists?(name:, **processed_context)

        !!create!(name:, **processed_context)
      end

      def rename(old_name, new_name, context: nil, force: false)
        deprecation_warning("rename", "Rabarber.rename_role")

        processed_context = process_context(context)
        role = find_by(name: process_role_name(old_name), **processed_context)

        raise Rabarber::NotFoundError, "Role not found" unless role

        name = process_role_name(new_name)

        return false if exists?(name:, **processed_context) || role.roleables.exists? && !force

        delete_roleables_cache(role, context: processed_context)

        role.update!(name:)
      end

      def remove(name, context: nil, force: false)
        deprecation_warning("remove", "Rabarber.delete_role")

        processed_context = process_context(context)
        role = find_by(name: process_role_name(name), **processed_context)

        raise Rabarber::NotFoundError, "Role not found" unless role

        return false if role.roleables.exists? && !force

        delete_roleables_cache(role, context: processed_context)

        !!role.destroy!
      end

      def assignees(name, context: nil)
        deprecation_warning("assignees", "#{Rabarber::Configuration.user_model_name}.with_role")

        find_by(name: process_role_name(name), **process_context(context))&.roleables || Rabarber::Configuration.user_model.none
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
      end

      private

      def deprecation_warning(method, alternative)
        callers = caller_locations.map(&:label)

        return if callers.include?(alternative) || callers.include?("ActiveRecord::Relation#scoping")

        ActiveSupport::Deprecation.new("6.0.0", "rabarber").warn("`Rabarber::Role.#{method}` method is deprecated and will be removed in the next major version, use `#{alternative}` instead.")
      end

      def delete_roleables_cache(role, context:)
        Rabarber::Core::Cache.delete(*role.roleables.pluck(:id).flat_map { [[_1, context], [_1, :all]] })
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
