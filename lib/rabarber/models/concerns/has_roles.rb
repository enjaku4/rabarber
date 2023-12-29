# frozen_string_literal: true

module Rabarber
  module HasRoles
    extend ActiveSupport::Concern

    included do
      raise Error, "Rabarber::HasRoles can only be included once" if defined?(@@included) && @@included != name

      @@included = name

      # TODO: try to make roles return role names instead of role objects
      has_and_belongs_to_many :roles, class_name: "Rabarber::Role",
                                      foreign_key: "roleable_id",
                                      join_table: "rabarber_roles_roleables"
    end

    def has_role?(*role_names)
      validate_role_names(role_names)

      roles.exists?(name: role_names)
    end

    def assign_roles(*role_names, create_new: true)
      validate_role_names(role_names)

      create_new_roles(role_names) if create_new

      roles << Role.where(name: role_names) - roles
    end

    def revoke_roles(*role_names)
      validate_role_names(role_names)

      self.roles = roles - Role.where(name: role_names)
    end

    private

    def validate_role_names(role_names)
      return if role_names.all? do |role_name|
        [Symbol, String].include?(role_name.class) && role_name.match?(/\A[a-z0-9_]+\z/)
      end

      raise(
        ArgumentError,
        "Role names must be symbols or strings and may only contain lowercase letters and underscores"
      )
    end

    def create_new_roles(role_names)
      new_roles = role_names - Role.names
      new_roles.each { |role_name| Role.create!(name: role_name) }
    end
  end
end
