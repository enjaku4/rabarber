# frozen_string_literal: true

module Rabarber
  class Role < ActiveRecord::Base
    self.table_name = "rabarber_roles"

    validates :name, presence: true, uniqueness: true, format: { with: Rabarber::Input::Roles::REGEX }

    has_and_belongs_to_many :roleables, join_table: "rabarber_roles_roleables"

    class << self
      def names
        pluck(:name).map(&:to_sym)
      end

      def add(name)
        delete_cache
        create(name: Rabarber::Input::Roles.new(name).process[0]).persisted?
      end

      def rename(old_name, new_name, force: false)
        role = find_by(name: Rabarber::Input::Roles.new(old_name).process[0])
        name = Rabarber::Input::Roles.new(new_name).process[0]

        return false if !role || assigned_to_roleables(role).any? && !force

        delete_cache
        delete_roleables_cache(role)

        role.update(name: name)
      end

      def delete(name, force: false)
        role = find_by(name: Rabarber::Input::Roles.new(name).process[0])

        return false if !role || assigned_to_roleables(role).any? && !force

        delete_cache
        delete_roleables_cache(role)

        role.destroy!.destroyed?
      end

      private

      def delete_cache
        Rabarber::Cache.delete(Rabarber::Cache::ALL_ROLES_KEY)
      end

      def delete_roleables_cache(role)
        assigned_to_roleables(role).each do |roleable_id|
          Rabarber::Cache.delete(Rabarber::Cache.key_for(roleable_id))
        end
      end

      def assigned_to_roleables(role)
        ActiveRecord::Base.connection.select_values(
          "SELECT roleable_id FROM rabarber_roles_roleables WHERE role_id = #{role.id}"
        )
      end
    end
  end
end
