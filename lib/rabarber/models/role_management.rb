# frozen_string_literal: true

module Rabarber
  module RoleManagement
    def roles(context: nil) = Rabarber::Role.list(context:)
    def all_roles = Rabarber::Role.list_all
    def create_roles(*names, context: nil) = Rabarber::Role.register(names, context:)
    def rename_role(old_name, new_name, context: nil, force: false) = Rabarber::Role.amend(old_name, new_name, context:, force:)
    def delete_roles(*names, context: nil, force: false) = Rabarber::Role.drop(names, context:, force:)
    def prune = Rabarber::Role.prune # rubocop:disable Rails/Delegate

    def create_role(name, context: nil)
      Rabarber.deprecator.warn("`Rabarber.create_role` method is deprecated and will be removed in the next major version, use `Rabarber.create_roles` instead", caller_locations(1))

      Rabarber::Role.deprecated_register(name, context:)
    end

    def delete_role(name, context: nil, force: false)
      Rabarber.deprecator.warn("`Rabarber.delete_role` method is deprecated and will be removed in the next major version, use `Rabarber.delete_roles` instead", caller_locations(1))

      Rabarber::Role.deprecated_drop(name, context:, force:)
    end
  end
end
