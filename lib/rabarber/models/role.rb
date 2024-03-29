# frozen_string_literal: true

module Rabarber
  class Role < ActiveRecord::Base
    self.table_name = "rabarber_roles"

    validates :name, presence: true, uniqueness: true, format: { with: Rabarber::Input::Role::REGEX }, strict: true

    has_and_belongs_to_many :roleables, join_table: "rabarber_roles_roleables"

    class << self
      def names
        pluck(:name).map(&:to_sym)
      end

      def add(name)
        name = process_role_name(name)

        return false if exists?(name:)

        !!create!(name:)
      end

      def rename(old_name, new_name, force: false)
        role = find_by(name: process_role_name(old_name))
        name = process_role_name(new_name)

        return false if !role || exists?(name:) || assigned_to_roleables(role).any? && !force

        delete_roleables_cache(role)

        role.update!(name:)
      end

      def remove(name, force: false)
        role = find_by(name: process_role_name(name))

        return false if !role || assigned_to_roleables(role).any? && !force

        delete_roleables_cache(role)

        !!role.destroy!
      end

      def assignees_for(name)
        Rabarber::HasRoles.roleable_class.joins(:rabarber_roles).where(
          rabarber_roles: { name: Rabarber::Input::Role.new(name).process }
        )
      end

      private

      def delete_roleables_cache(role)
        Rabarber::Cache.delete(*assigned_to_roleables(role))
      end

      def assigned_to_roleables(role)
        ActiveRecord::Base.connection.select_values(
          "SELECT roleable_id FROM rabarber_roles_roleables WHERE role_id = '#{role.id}'"
        )
      end

      def process_role_name(name)
        Rabarber::Input::Role.new(name).process
      end
    end
  end
end
