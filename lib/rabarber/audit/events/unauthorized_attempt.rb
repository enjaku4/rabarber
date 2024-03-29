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
          "[Unauthorized Attempt] #{identity} attempted to access '#{path}'"
        end

        def identity_with_roles?
          true
        end

        def path
          specifics.fetch(:path)
        end
      end
    end
  end
end
