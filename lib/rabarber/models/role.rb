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
        delete_cache
        # TODO: process input
        # TODO: don't rename if role is assigned, unless force is true
        # TODO: delete user's cache to whom the role is assigned if force is true
        find_by(name: old_name)&.update(name: new_name)
        # TODO: return something meaningful
      end

      def delete(name, force: false)
        delete_cache
        # TODO: process input
        # TODO: don't delete if role is assigned, unless force is true
        # TODO: delete user's cache to whom the role is assigned if force is true
        find_by(name: name)&.destroy
        # TODO: return something meaningful
      end

      private

      def delete_cache
        Rabarber::Cache.delete(Rabarber::Cache::ALL_ROLES_KEY)
      end
    end
  end
end
