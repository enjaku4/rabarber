# frozen_string_literal: true

module Rabarber
  module Audit
    module Events
      class RolesAssigned < Base
        private

        def nil_roleable_allowed?
          false
        end

        def log_level
          :info
        end

        def message
          # TODO: roles with context
          "[Role Assignment] #{identity} has been assigned the following roles: #{roles_to_assign}, current roles: #{current_roles}"
        end

        def identity_with_roles?
          false
        end

        def roles_to_assign
          specifics.fetch(:roles_to_assign)
        end

        def current_roles
          specifics.fetch(:current_roles)
        end
      end
    end
  end
end
