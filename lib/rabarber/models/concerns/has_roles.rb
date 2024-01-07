# frozen_string_literal: true

module Rabarber
  module HasRoles
    extend ActiveSupport::Concern

    included do
      raise Error, "Rabarber::HasRoles can only be included once" if defined?(@@included) && @@included != name

      @@included = name

      has_and_belongs_to_many :rabarber_roles, class_name: "Rabarber::Role",
                                               foreign_key: "roleable_id",
                                               join_table: "rabarber_roles_roleables"
    end

    def roles
      rabarber_roles.names
    end

    def has_role?(*role_names)
      (roles & RoleNames.pre_process(role_names)).any?
    end

    def assign_roles(*role_names, create_new: true)
      roles_to_assign = RoleNames.pre_process(role_names)

      create_new_roles(roles_to_assign) if create_new

      rabarber_roles << Role.where(name: roles_to_assign) - rabarber_roles
    end

    def revoke_roles(*role_names)
      self.rabarber_roles = rabarber_roles - Role.where(name: RoleNames.pre_process(role_names))
    end

    private

    def create_new_roles(role_names)
      new_roles = role_names - Role.names
      new_roles.each { |role_name| Role.create!(name: role_name) }
    end
  end
end
