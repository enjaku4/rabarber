# frozen_string_literal: true

module Rabarber
  module Audit
    module Events
      class RolesRevoked < Base
        private

        def nil_roleable_allowed?
          false
        end

        def log_level
          :info
        end

        def message
          # TODO: roles with context
          "[Role Revocation] #{identity} has been revoked from the following roles: #{roles_to_revoke}, current roles: #{current_roles}"
        end

        def identity_with_roles?
          false
        end

        def roles_to_revoke
          specifics.fetch(:roles_to_revoke)
        end

        def current_roles
          specifics.fetch(:current_roles)
        end
      end
    end
  end
end
