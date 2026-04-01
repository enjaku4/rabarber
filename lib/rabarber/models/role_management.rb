# frozen_string_literal: true

module Rabarber
  module RoleManagement
    def roles(context: nil) = Rabarber::Role.list(context:)
    def all_roles = Rabarber::Role.list_all
    def create_role(name, context: nil) = Rabarber::Role.register(name, context:)
    def rename_role(old_name, new_name, context: nil, force: false) = Rabarber::Role.amend(old_name, new_name, context:, force:)
    def delete_role(name, context: nil, force: false) = Rabarber::Role.drop(name, context:, force:)
    def prune = Rabarber::Role.prune # rubocop:disable Rails/Delegate
  end
end
