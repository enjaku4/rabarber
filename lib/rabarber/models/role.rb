# frozen_string_literal: true

module Rabarber
  class Role < ActiveRecord::Base
    self.table_name = "rabarber_roles"

    validates :name, presence: true,
                     uniqueness: { scope: [:context_type, :context_id] },
                     format: { with: Rabarber::Input::Role::REGEX },
                     strict: true

    belongs_to :context, polymorphic: true, optional: true

    before_destroy :delete_assignments

    class << self
      def names(context: nil)
        where(process_context(context)).pluck(:name).map(&:to_sym)
      end

      def all_names
        includes(:context).each_with_object({}) do |role, hash|
          (hash[role.context] ||= []) << role.name.to_sym
        rescue ActiveRecord::RecordNotFound
          next
        end
      rescue NameError => e
        raise Rabarber::Error, "Context not found: class #{e.name} may have been renamed or deleted"
      end

      def add(name, context: nil)
        name = process_role_name(name)
        processed_context = process_context(context)

        return false if exists?(name:, **processed_context)

        !!create!(name:, **processed_context)
      end

      def rename(old_name, new_name, context: nil, force: false)
        processed_context = process_context(context)
        role = find_by(name: process_role_name(old_name), **processed_context)
        name = process_role_name(new_name)

        return false if !role || exists?(name:, **processed_context) || assigned_to_roleables(role).any? && !force

        delete_roleables_cache(role, context: processed_context)

        role.update!(name:)
      end

      def remove(name, context: nil, force: false)
        processed_context = process_context(context)
        role = find_by(name: process_role_name(name), **processed_context)

        return false if !role || assigned_to_roleables(role).any? && !force

        delete_roleables_cache(role, context: processed_context)

        !!role.destroy!
      end

      def assignees(name, context: nil)
        Rabarber::Configuration.instance.user_model.joins(:rabarber_roles).where(
          rabarber_roles: { name: process_role_name(name), **process_context(context) }
        )
      end

      private

      def delete_roleables_cache(role, context:)
        assigned_to_roleables(role).each_slice(1000) do |ids|
          Rabarber::Core::Cache.delete(*ids.flat_map { [[_1, context], [_1, :all]] })
        end
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

    def context
      return context_type.constantize if context_type.present? && context_id.blank?

      record = super

      raise ActiveRecord::RecordNotFound.new(nil, context_type, nil, context_id) if context_id.present? && !record

      record
    end

    def delete_assignments
      ActiveRecord::Base.connection.execute(
        ActiveRecord::Base.sanitize_sql(
          ["DELETE FROM rabarber_roles_roleables WHERE role_id = ?", id]
        )
      )
    end
  end
end
