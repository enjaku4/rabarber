# frozen_string_literal: true

module Rabarber
  module Audit
    module Events
      class RolesRevoked < Base
        private

        def log_level
          :info
        end

        def message
          "[Role Revocation] #{identity} has been revoked from the following roles: #{roles_to_revoke}, current roles: #{current_roles}"
        end

        def identity
          roleable_identity(with_roles: false)
        end

        def roles_to_revoke
          specifics.fetch(:roles_to_revoke)
        end

        def current_roles
          specifics.fetch(:current_roles)
        end

        def nil_roleable_allowed?
          false
        end
      end
    end
  end
end
