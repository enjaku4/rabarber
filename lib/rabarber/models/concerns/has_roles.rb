# frozen_string_literal: true

module Rabarber
  module HasRoles
    extend ActiveSupport::Concern

    included do
      raise Error, "Rabarber::HasRoles can only be included once" if defined?(@@included) && @@included != name

      @@included = name

      has_and_belongs_to_many :roles, class_name: "Rabarber::Role",
                                      foreign_key: "roleable_id",
                                      join_table: "rabarber_roles_roleables"
    end

    def has_role?(*role_names)
      unless role_names.all? { |arg| arg.is_a?(Symbol) || arg.is_a?(String) }
        raise(ArgumentError, "Role names must be symbols or strings")
      end

      roles.exists?(name: role_names)
    end

    def assign_roles(*role_names, create_new: true)
      unless role_names.all? { |arg| arg.is_a?(Symbol) || arg.is_a?(String) }
        raise(ArgumentError, "Role names must be symbols or strings")
      end

      if create_new && (new_roles = role_names - Role.names).any?
        new_roles.each { |role| Role.create!(name: role) }
      end

      roles << Role.where(name: role_names) - roles
    end

    def revoke_roles(*role_names)
      unless role_names.all? { |arg| arg.is_a?(Symbol) || arg.is_a?(String) }
        raise(ArgumentError, "Role names must be symbols or strings")
      end

      self.roles = roles - Role.where(name: role_names)
    end
  end
end
