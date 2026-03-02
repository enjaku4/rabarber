# frozen_string_literal: true

module Rabarber
  module RoleManagement
    def roles(context: nil) = Rabarber::Role.names(context:)
    def all_roles = Rabarber::Role.all_names
    def create_role(name, context: nil) = Rabarber::Role.add(name, context:)
    def rename_role(old_name, new_name, context: nil, force: false) = Rabarber::Role.rename(old_name, new_name, context:, force:)
    def delete_role(name, context: nil, force: false) = Rabarber::Role.remove(name, context:, force:)
    def prune = Rabarber::Role.prune # rubocop:disable Rails/Delegate
  end
end
