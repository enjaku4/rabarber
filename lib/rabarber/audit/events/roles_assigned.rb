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
          "[Role Assignment] #{identity} | context: #{human_context} | assigned: #{roles_to_assign} | current: #{current_roles}"
        end

        def context
          specifics.fetch(:context)
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
