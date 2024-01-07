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

    # TODO
    def has_role?(*role_names)
      validate_role_names(role_names)

      (roles & role_names).any?
    end

    # TODO
    def assign_roles(*role_names, create_new: true)
      validate_role_names(role_names)

      create_new_roles(role_names) if create_new

      rabarber_roles << Role.where(name: role_names) - rabarber_roles
    end

    # TODO
    def revoke_roles(*role_names)
      validate_role_names(role_names)

      self.rabarber_roles = rabarber_roles - Role.where(name: role_names)
    end

    private

    def validate_role_names(role_names)
      return if role_names.all? { |role_name| role_name.is_a?(Symbol) && role_name.to_s.match?(Role::NAME_REGEX) }

      raise(
        InvalidArgumentError,
        "Role names must be Symbols and may only contain lowercase letters, numbers and underscores"
      )
    end

    def create_new_roles(role_names)
      new_roles = role_names - Role.names
      new_roles.each { |role_name| Role.create!(name: role_name) }
    end
  end
end
