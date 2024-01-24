# frozen_string_literal: true

module Rabarber
  module HasRoles
    module Internal
      extend ActiveSupport::Concern

      def roles
        rabarber_roles.names
      end

      def has_role?(*role_names)
        (roles & process_role_names(role_names)).any?
      end

      def assign_roles(*role_names, create_new: true)
        roles_to_assign = process_role_names(role_names)

        create_new_roles(roles_to_assign) if create_new

        rabarber_roles << Role.where(name: roles_to_assign) - rabarber_roles
      end

      def revoke_roles(*role_names)
        self.rabarber_roles = rabarber_roles - Role.where(name: process_role_names(role_names))
      end

      alias remove_roles revoke_roles
      alias add_roles assign_roles

      private

      def create_new_roles(role_names)
        new_roles = role_names - Role.names
        new_roles.each { |role_name| Role.create!(name: role_name) }
      end

      def process_role_names(role_names)
        Input::Roles.new(role_names).process
      end
    end
  end
end
