# frozen_string_literal: true

module Rabarber
  module Audit
    module Events
      class UnauthorizedAttempt < Base
        private

        def nil_roleable_allowed?
          true
        end

        def log_level
          :warn
        end

        def message
          "[Unauthorized Attempt] #{identity}#{roles}path: '#{path}'".tr('"', "'")
        end

        def roles
          if roleable
            roles_list = roleable.rabarber_roles.group_by { |role| role.context.to_s }.transform_values { |roles|
              roles.pluck(:name).map(&:to_sym)
            }.sort.to_h

            " | roles: #{roles_list}, "
          else
            " | "
          end
        end

        def path
          specifics.fetch(:path)
        end
      end
    end
  end
end
