# frozen_string_literal: true

module Rabarber
  class Role < ActiveRecord::Base
    self.table_name = "rabarber_roles"

    validates :name, presence: true,
                     uniqueness: { scope: [:context_type, :context_id] },
                     format: { with: Rabarber::Input::Role::REGEX },
                     strict: true

    has_and_belongs_to_many :roleables, join_table: "rabarber_roles_roleables"

    class << self
      def names(context: nil)
        where(Rabarber::Input::Context.new(context).process).pluck(:name).map(&:to_sym)
      end

      def add(name, context: nil)
        name = process_role_name(name)
        processed_context = process_context(context)

        return false if exists?(name: name, **processed_context)

        !!create!(name: name, **processed_context)
      end

      def rename(old_name, new_name, context: nil, force: false)
        processed_context = process_context(context)
        role = find_by(name: process_role_name(old_name), **processed_context)
        name = process_role_name(new_name)

        return false if !role || exists?(name: name, **processed_context) || assigned_to_roleables(role).any? && !force

        delete_roleables_cache(role, context: processed_context)

        role.update!(name: name)
      end

      def remove(name, context: nil, force: false)
        processed_context = process_context(context)
        role = find_by(name: process_role_name(name), **processed_context)

        return false if !role || assigned_to_roleables(role).any? && !force

        delete_roleables_cache(role, context: processed_context)

        !!role.destroy!
      end

      def assignees(name, context: nil)
        Rabarber::HasRoles.roleable_class.joins(:rabarber_roles).where(
          rabarber_roles: { name: Rabarber::Input::Role.new(name).process, **process_context(context) }
        )
      end

      private

      def delete_roleables_cache(role, context:)
        Rabarber::Core::Cache.delete(*assigned_to_roleables(role), context: context)
      end

      def assigned_to_roleables(role)
        ActiveRecord::Base.connection.select_values(
          ActiveRecord::Base.sanitize_sql(
            ["SELECT roleable_id FROM rabarber_roles_roleables WHERE role_id = ?", role.id]
          )
        )
      end

      def process_role_name(name)
        Rabarber::Input::Role.new(name).process
      end

      def process_context(context)
        Rabarber::Input::Context.new(context).process
      end
    end
  end
end
