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
          "[Role Revocation] #{identity} | context: '#{context}', revoked roles: #{roles_to_revoke}, current roles: #{current_roles}"
        end

        def context
          specifics.fetch(:context).to_s
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
