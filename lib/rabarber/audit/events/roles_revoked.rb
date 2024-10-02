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
          "[Role Revocation] #{identity} | context: #{human_context} | revoked: #{roles_to_revoke} | current: #{current_roles}"
        end

        def context
          specifics.fetch(:context)
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
